import 'dart:io';
import 'package:angel_auth/angel_auth.dart';
import 'package:angel_auth_google/angel_auth_google.dart';
import 'package:angel_compress/angel_compress.dart';
import 'package:angel_diagnostics/angel_diagnostics.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:googleapis/plus/v1.dart';

const scopes = const [
  PlusApi.PlusMeScope,
  PlusApi.UserinfoEmailScope,
  PlusApi.UserinfoProfileScope
];

main() async {
  final app = new Angel();

  // Disabling cookie support will force our auth to be stateless
  // This could be good or bad, depending on how you look at it.
  final auth = new AngelAuth(allowCookie: false);

  auth.strategies.add(new GoogleStrategy(config: {
    'id':
        '879916772461-i7htk1jo48ubv18dbe9pvce4m6lbka9n.apps.googleusercontent.com',
    'secret': 'ZH3uaWy7Jtb7jtVRLcRRBdD0',
    'redirect_uri': 'http://localhost:3000/auth/google/callback'
  }, callback: callback, scopes: scopes));

  auth.serializer = (Person user) async => user.id;

  auth.deserializer = (id) async {
    return {'id': id};
  };

  app.get('/', (ResponseContext res) async {
    final index = new File.fromUri(Platform.script.resolve('./index.html'));
    return await res.streamFile(index);
  });

  app.group('/auth/google', (router) {
    router.get('/', auth.authenticate('google'));

    router.get(
        '/callback',
        auth.authenticate('google', new AngelAuthOptions(callback:
            (RequestContext req, ResponseContext res, String jwt) async {
          // If we are adamant about not using sessions, we can just
          // stick the JWT into the query string.
          return res.redirect('/home?token=$jwt');
        })));
  });

  app.all('/home', (req, res) async {
    print('Dumping cookies: ${req.cookies}');
    return true;
  });

  app.chain('auth').get('/home', (RequestContext req, res) {
    for (final cookie in req.cookies) {
      print('COOKIE: ${cookie.name} => ${cookie.value}');
    }

    res.write('Hello, user #${req.user['id']}!');
    return false;
  });

  app.all('*', () {
    throw new AngelHttpException.NotFound();
  });

  app.responseFinalizers
    ..add(gzip())
    ..add((req, res) async {
      print('Outgoing cookies: ${res.cookies}');
    });

  await app.configure(auth);

  await new DiagnosticsServer(app, new File('log.txt')).startServer(null, 3000);
}

/// Your callback should accept a Google+ user. ;)
///
/// I considered forcing you to handle Google+ users in
/// your serializer, but this approach allows users to
/// sign in with multiple platforms.
callback(_, Person profile) => profile;
