import 'package:mysql1/mysql1.dart';

class MySQL{
  static String host = 'sql10.freesqldatabase.com',
  user = 'sql10666856',
  password = 'dvRgytDnPa',
  db = 'sql10666856';
  static int port = 3306;

  MySQL();

  Future<MySqlConnection> getConnetion() async{
    var settings = ConnectionSettings(
      host: host,
      port: port,
      user: user,
      password: password,
      db: db,
    );
    return await MySqlConnection.connect(settings);
  }
}