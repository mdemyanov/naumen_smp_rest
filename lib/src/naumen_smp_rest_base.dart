import 'dart:async';
import 'dart:convert';

import 'package:http/browser_client.dart';
import 'package:http/http.dart';

/// Заголовки для REST API запросов в сторону сервера Naumen SMP
final _headers = {'Content-Type': 'application/json'};

/// Адрес REST API сервиса Naumen SMP для поиска объектов
final String _find = '/sd/services/rest/find';

/// Адрес REST API сервиса Naumen SMP для получения объекта по UUID
final String _get = '/sd/services/rest/get';

/// Адрес REST API сервиса Naumen SMP для редактирования объекта
final String _edit = '/sd/services/rest/edit';

/// Адрес REST API сервиса Naumen SMP для создания объекта M2M
final String _create = '/sd/services/rest/create-m2m';

/// Адрес REST API сервиса Naumen SMP для исполнения скриптовых модулей или удаленного выполнения скриптов
final String _execPost = '/sd/services/rest/exec-post';

final BrowserClient _http = BrowserClient();

/// Поиск объектов, с возвращением первого
///
/// Принимает на вход идентификатор метакласса [fqn] и ассоциативный список кодов
/// атрибутов и их значений [attributes]
Future<Map> findFirst(String fqn, Map attributes) async {
  try {
    List data = await find(fqn, attributes);
    return data.length > 0 ? data.first : {};
  } catch (e) {
    print(e.toString());
    return {};
  }
}

/// Получить объект по URL
///
/// Принимает на вход ссылку на объект [url] вида server/sd/services/rest/get/uuid
Future<Map> getObjectByUrl(String url) async {
  try {
    final response = await _http.get(url);
    return _extractData(response);
  } catch (e) {
    print('[utils.getObjectByUrl] ${e.toString()}');
    return {};
  }
}

/// Получить объект по UUID
///
/// Принимает на вход идентификатор объекта [uuid]
Future<Map> get(String uuid) async {
  try {
    final response = await _http.get('$_get/$uuid');
    return _extractData(response);
  } catch (e) {
    print('[utils.get] ${e.toString()}');
    return {};
  }
}

/// Поиск объектов
///
/// Принимает на вход идентификатор метакласса [fqn] и ассоциативный список кодов
/// атрибутов и их значений [attributes]
Future<List> find(String fqn, Map attributes) async {
  try {
    final response = await _http.get(
        Uri.https('', '$_find/$fqn/${_encodeParams(attributes)}')
            .toString()
            .substring(6));
    return _extractData(response);
  } catch (e) {
    print('[utils.find] ${e.toString()}');
    return [];
  }
}

/// Добавление объекта
///
/// Принимает на вход идентификатор метакласса [fqn] и ассоциативный список кодов
/// атрибутов и устанавливаемых значений [attributes]
Future<Map> create(String fqn, Map attributes) async {
  try {
    final response = await _http.post('$_create/$fqn',
        headers: _headers, body: json.encode(attributes));
    return _extractData(response);
  } catch (e) {
    print('[utils.create] ${e.toString()}');
    return {};
  }
}

/// Выполнение метода пользовательского модуля через запрос POST
///
/// Принимает на вход [methodLink] в формате moduleCode.methodName, а также
/// [requestContent] в виде ассоциативного массива
Future<Map> execPostContent(String methodLink, Map requestContent) async {
  try {
    final response = await _http.post(
        '$_execPost?func=modules.$methodLink&params=requestContent,user',
        headers: _headers,
        body: json.encode(requestContent));
    return _extractData(response);
  } catch (e) {
    print('[utils.execPost: $methodLink] ${e.toString()}');
    return {};
  }
}

/// Выполнение метода пользовательского модуля через запрос POST
///
/// Принимает на вход [methodLink] в формате moduleCode.methodName, а также
/// [arguments] в виде коллекции строк
Future<Map> execPostArgs(String methodLink, List<String> arguments) async {
  try {
    final response = await _http.post(
        '$_execPost?func=modules.$methodLink&params=${arguments.join(',')}',
        headers: _headers);
    return _extractData(response);
  } catch (e) {
    print('[utils.execPost: $methodLink] ${e.toString()}');
    return {};
  }
}

/// Редактирование атрибутов объекта
///
/// Принимает на вход идентификатор объекта [uuid] и ассоциативный список кодов
/// изменяемых атрибутов и устанавливаемых значений [attributes]
Future<String> edit(String uuid, Map attributes) async {
  final String body = json.encode(attributes);
  try {
    final response =
    await _http.post('$_edit$uuid', headers: _headers, body: body);
    return response.body;
  } catch (e) {
    print('[utils.edit: $uuid] ${e.toString()}');
    return null;
  }
}

/// Внутренний метод для преобразования ответа [resp] к читаемому виду
///
/// Преобразует ответ сервера [resp] с помощью json.decode
_extractData(Response resp) => json.decode(resp.body);

/// Внутренний метод для приведения [params] к пригодному виду
///
/// Приводит [params] к виду UrlBase64, а также добавляет служебные символы

String _encodeParams(Map params) =>
    '40x' +
        Base64Codec.urlSafe().encode(JsonEncoder().convert(params).codeUnits);
