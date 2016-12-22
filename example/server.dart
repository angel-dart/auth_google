import 'dart:io';
import 'package:angel_auth/angel_auth.dart';
import 'package:angel_auth_google/angel_auth_google.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:googleapis/plus/v1.dart';

const scopes = const [
  PlusApi.PlusMeScope,
  PlusApi.UserinfoEmailScope,
  PlusApi.UserinfoProfileScope
];

main() async {
  final app = new Angel();
  final auth = new AngelAuth();

  auth.strategies.add(new GoogleStrategy(config: {
    'id':
        '879916772461-i7htk1jo48ubv18dbe9pvce4m6lbka9n.apps.googleusercontent.com',
    'secret': 'ZH3uaWy7Jtb7jtVRLcRRBdD0',
    'redirect_uri': 'http://localhost:3000/auth/google/callback'
  }, callback: callback, scopes: scopes));

  auth.serializer = (Person user) => user.id;

  auth.deserializer = (id) async {
    return {'id': id};
  };

  await app.configure(auth);

  app.get('/', (ResponseContext res) async {
    final index = new File.fromUri(Platform.script.resolve('./index.html'));
    return await res.streamFile(index);
  });

  app.group('/auth/google', (router) {
    router.get('/', auth.authenticate('google'));

    /// We can just return JSON here.
    ///
    /// In an SPA, we can access this APi
    /// to easily obtain a JWT.
    router.get(
        '/callback',
        auth.authenticate(
            'google', new AngelAuthOptions(canRespondWithJson: false)));
  });

  app.get('/home', (RequestContext req, res) {
    for (final cookie in req.cookies) {
      print('COOKIE: ${cookie.name} => ${cookie.value}');
    }

    res.write('Hello, user #${req.user['id']}!');
    return false;
  });

  app.all('*', () {
    throw new AngelHttpException.NotFound();
  });

  final server = await app.startServer();
  print('Listening at http://${server.address.address}:${server.port}');
}

/// Your callback should accept a Google+ user. ;)
///
/// I considered forcing you to handle Google+ users in
/// your serializer, but this approach allows users to
/// sign in with multiple platforms.
callback(_, Person profile) => profile;
