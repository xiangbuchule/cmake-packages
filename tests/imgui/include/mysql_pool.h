#ifndef __MYSQL_POOL__
#define __MYSQL_POOL__

#include <condition_variable>
#include <functional>
#include <list>
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
  private:
    std::unique_ptr<sql::mysql::MySQL_Driver, std::function<void(sql::mysql::MySQL_Driver *)>> _driver;
    std::shared_ptr<sql::ConnectOptionsMap>                                                    _config;
    std::mutex                                                                                 _mutex;
    std::condition_variable                                                                    _cond;
    size_t                                                                                     _max;
    size_t                                                                                     _min;
    // 忙碌
    std::list<std::shared_ptr<sql::Connection>> _busy_conns;
    // 空闲
    std::list<std::shared_ptr<sql::Connection>> _free_conns;

  public:
    MySQLPool(std::shared_ptr<sql::ConnectOptionsMap> &&config, size_t min, size_t max);
    std::shared_ptr<sql::Connection> get_connection();
    ~MySQLPool();

    size_t get_size();
    size_t get_free_size();
    size_t get_busy_size();
    size_t get_min();
    size_t get_max();
};

#endif