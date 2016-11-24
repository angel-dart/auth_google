library angel_auth.google.src.strategy;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:angel_auth/angel_auth.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:googleapis/plus/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis_auth/src/utils.dart' as utils;
import 'package:http/http.dart' as http;

class GoogleOauth2Strategy implements AuthStrategy {
  final Map config = {};
  final List<String> scopes = [];

  @override
  String name = 'google';

  GoogleOauth2Strategy({Map config: const {}, List<String> scopes: const []}) {
    this.config.addAll(config ?? {});

    if (scopes != null) this.scopes.addAll(scopes);
  }

  @override
  Future authenticate(RequestContext req, ResponseContext res,
      [AngelAuthOptions options]) async {
    if (req.query.containsKey('code')) {
      return await authenticateCallback(req, res, options);
    } else {
      var url =
          'https://accounts.google.com/o/oauth2/v2/auth?response_type=code&include_granted_scopes=true';
      url += '&client_id=${Uri.encodeQueryComponent(config['id'])}';
      url +=
          '&redirect_uri=${Uri.encodeQueryComponent(config['redirect_uri'])}';
      url += '&scope=${scopes.map(Uri.encodeQueryComponent).join('%20')}';
      return res.redirect(url);
    }
  }

  Future authenticateCallback(
      RequestContext req, ResponseContext res, AngelAuthOptions options) async {
    // Google should send us an authorization code...
    String code = req.query['code'];
    if (code == null || code.isEmpty) throw new AngelHttpException.BadRequest();

    try {
      // Transform this into an access token
      final client = new http.Client();
      final response = await client
          .post('https://www.googleapis.com/oauth2/v4/token', body: {
        'code': code,
        'client_id': config['id'],
        'client_secret': config['secret'],
        'redirect_uri': config['redirect_uri'],
        'grant_type': 'authorization_code'
      });

      final token = JSON.decode(response.body);
      final accessToken = new AccessToken(token['token_type'],
          token['access_token'], utils.expiryDate(token['expires_in']));
      final credentials =
          new AccessCredentials(accessToken, token['refresh_token'], scopes);

      // Create an HTTP client that is prepped to access Google+ API
      final clientId = new ClientId(config['id'], config['secret']);
      final authClient = autoRefreshingClient(clientId, credentials, client);
      final api = new PlusApi(authClient);

      // Fetch info about the user
      Person me = await api.people.get('me');
      authClient.close();
      client.close();

      return me;
    } catch (e) {
      if (options.failureRedirect != null &&
          options.failureRedirect.isNotEmpty) {
        res.redirect(options.failureRedirect, code: HttpStatus.UNAUTHORIZED);
        return false;
      }
      return false;
    }
  }

  @override
  Future<bool> canLogout(RequestContext req, ResponseContext res) async {
    return true;
  }
}
