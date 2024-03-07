#include <mutex>
#include <vector>

#include "jdbc/cppconn/connection.h"
#include "jdbc/cppconn/driver.h"
#include "jdbc/cppconn/exception.h"
#include "jdbc/mysql_connection.h"
#include "jdbc/mysql_driver.h"

#include "mysql_pool.h"

MySQLPool::MySQLPool(std::shared_ptr<sql::ConnectOptionsMap> &&config, size_t min, size_t max)
    : _config(config), _min(min), _max(max) {
    this->_driver = std::unique_ptr<sql::mysql::MySQL_Driver, std::function<void(sql::mysql::MySQL_Driver *)>>(sql::mysql::get_mysql_driver_instance(), [](sql::mysql::MySQL_Driver *p) { delete dynamic_cast<sql::mysql::MySQL_Driver *>(p); });
    while (this->_free_conns.size() < min) {
        this->_free_conns.push_back(std::shared_ptr<sql::Connection>(
            this->_driver->connect(*config),
            [](sql::Connection *p) {
                delete p;
            }));
    }
}
std::shared_ptr<sql::Connection> MySQLPool::get_connection() {
    std::unique_lock<std::mutex> lock(this->_mutex);
    // 遍历将释放的忙碌连接
    size_t free_sum = 0;
    for (auto iter = this->_busy_conns.begin(); iter != this->_busy_conns.end();) {
        if (iter->use_count() == 1) {
            this->_free_conns.push_back(*iter);
            this->_busy_conns.erase(iter);
            ++free_sum;
            continue;
        }
        ++iter;
    }
    if (free_sum == 0) {
        if (this->_busy_conns.size() + this->_free_conns.size() < this->_max && this) {
            size_t num = this->_max - this->_busy_conns.size() - this->_free_conns.size();
            if (num > 2) {
                num = num / 2;
            }
            while (num > 0) {
                this->_free_conns.push_back(std::shared_ptr<sql::Connection>(
                    this->_driver->connect(*this->_config),
                    [](sql::Connection *p) {
                        delete p;
                    }));
            }
        }
    } else {
        this->_cond.notify_one();
    }
    // 等待
    this->_cond.wait(lock, [this]() -> bool { return this->get_free_size() > 0; });
    // 取出free
    auto result = this->_free_conns.front();
    this->_free_conns.pop_front();
    // 放入忙碌
    this->_busy_conns.push_back(result);
    return result;
}
MySQLPool::~MySQLPool() {
    this->_busy_conns.clear();
    this->_free_conns.clear();
}

size_t MySQLPool::get_size() {
    return this->_free_conns.size() + this->_busy_conns.size();
}
size_t MySQLPool::get_free_size() {
    return this->_free_conns.size();
}
size_t MySQLPool::get_busy_size() {
    return this->_busy_conns.size();
}
size_t MySQLPool::get_min() {
    return this->_min;
}
size_t MySQLPool::get_max() {
    return this->_max;
}