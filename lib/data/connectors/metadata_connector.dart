import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:pocketcrm/core/auth/auth_service.dart';
import 'package:pocketcrm/domain/models/metadata/object_metadata.dart';

class MetadataConnector {
  final GraphQLClient client;
  final AuthService? authService;

  MetadataConnector({required this.client, this.authService});

  Future<List<ObjectMetadata>> getWorkspaceMetadata() async {
    const storage = FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));
    final token = await storage.read(key: 'api_token');
    final instanceUrl = await storage.read(key: 'instance_url');

    if (token == null || instanceUrl == null) {
      return [];
    }

    try {
      final url = Uri.parse('$instanceUrl/rest/metadata/objects');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('REST API error: ${response.statusCode} - ${response.body}');
      }

      final jsonBody = jsonDecode(response.body);
      
      List dataList = [];
      if (jsonBody is List) {
        dataList = jsonBody;
      } else if (jsonBody is Map) {
        if (jsonBody['data'] is List) {
          dataList = jsonBody['data'];
        } else if (jsonBody['data'] is Map && jsonBody['data']['objects'] is List) {
          dataList = jsonBody['data']['objects'];
        } else if (jsonBody['objects'] is List) {
          dataList = jsonBody['objects'];
        } else if (jsonBody['data'] is Map && jsonBody['data']['objects'] is Map && jsonBody['data']['objects']['edges'] is List) {
          // Fallback if REST strangely wraps in edges
          final edges = jsonBody['data']['objects']['edges'] as List;
          dataList = edges.map((e) => e['node']).toList();
        }
      }

      return dataList.map((obj) {
        final fieldsList = obj['fields'] as List? ?? [];
        
        final mappedNode = Map<String, dynamic>.from(obj);
        mappedNode['fields'] = fieldsList;

        return ObjectMetadata.fromJson(mappedNode);
      }).toList();
    } catch (e) {
      throw Exception('REST fetch failed: $e');
    }
  }
}
