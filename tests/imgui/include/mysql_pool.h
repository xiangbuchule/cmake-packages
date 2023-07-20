#ifndef __MYSQL_POOL__
#define __MYSQL_POOL__

#include <condition_variable>
#include <deque>
#include <memory>
#include <mutex>

#include "jdbc/cppconn/connection.h"
#include "jdbc/cppconn/driver.h"
#include "jdbc/cppconn/exception.h"
#include "jdbc/cppconn/prepared_statement.h"
#include "jdbc/cppconn/resultset.h"
#include "jdbc/cppconn/statement.h"
#include "jdbc/mysql_connection.h"
#include "jdbc/mysql_driver.h"
#include "mysqlx/xdevapi.h"

class MySQLPool {
    enum DriverState {
        FREE,
        BUSY
    };
    struct Driver {
        std::shared_ptr<sql::mysql::MySQL_Driver> driver;
        std::shared_ptr<sql::Connection>          connection;
        DriverState                               state;
    };

  private:
    std::mutex                          _mutex;
    std::condition_variable             _cond;
    size_t                              max;
    size_t                              min;
    std::deque<std::shared_ptr<Driver>> driver;

    void resize();

  public:
    MySQLPool();
    std::shared_ptr<Driver> get_driver() {
        std::unique_lock<std::mutex> lock(this->_mutex);
        auto data = this->driver.emplace_front();
        if (data->state == DriverState::BUSY) {
            if (this->driver.size() < this->max) {
                auto new_data   = std::make_shared<Driver>();
                new_data->state = DriverState::BUSY;
                this->driver.push_back(new_data);
                return new_data;
            } else {
                this->_cond.wait(lock);
            }
        }
        data->state = DriverState::BUSY;
        this->driver.push_back(data);
        return data;
    }
    std::shared_ptr<sql::Connection> get_connection();
    ~MySQLPool();
};

#endif