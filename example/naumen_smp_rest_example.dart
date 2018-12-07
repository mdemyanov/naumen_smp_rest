import 'package:naumen_smp_rest/naumen_smp_rest.dart' as utils;

main() async {
  /// Получить объект по uuid
  var root = await utils.get('root\$101');
  print(root);
  /// Найти все неархивные команды
  var teams = await utils.find('team', {'removed':false});
  print('Найдено команд: ${teams.length}');
}
