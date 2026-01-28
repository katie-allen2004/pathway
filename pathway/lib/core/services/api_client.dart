import 'dart:convert';
import 'package:http/http.dart' as http; 

class ApiClient // file still needs work 
{
  final String baseUrl = 'https://api.example.com/';//placeholder url 
  Future<dynamic> get(String path) async {
    final response = await http.get(Uri.parse('$baseUrl$path'));
    if(response.statusCode == 200)
    {
      return json.decode(response.body);
    }
    else
    {
      throw Exception("Azure Error: ${response.statusCode}");
    }
  }

  Future<dynamic> post(String path, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      body: json.encode(data),
      headers: {'Content-Type': 'application/json'},
    );

    return json.decode(response.body);
  }
}