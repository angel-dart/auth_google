import 'dart:io';
import 'package:angel_auth/angel_auth.dart';
import 'package:angel_auth_google/angel_auth_google.dart';
import 'package:angel_framework/angel_framework.dart';
import 'package:logging/logging.dart';
import 'package:googleapis/plus/v1.dart';
import 'pretty_logging.dart';

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
        '715118808787-gcfcng89n120su115kv66gerjb93e8et.apps.googleusercontent.com',
    'secret': 'QXjgDf2wF_nK_7fpZ1FNU71d',
    'redirect_uri': 'http://localhost:3000/auth/google/callback'
  }, callback: callback, scopes: scopes));

  auth.serializer = (Person user) async => user.id;

  auth.deserializer = (id) async {
    return {'id': id};
  };

  app.use(auth.decodeJwt);

  app.get('/', (ResponseContext res) async {
    final index = new File.fromUri(Platform.script.resolve('./index.html'));
    await res.streamFile(index);
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

  app.chain(requireAuth).get('/home', (RequestContext req, res) {
    for (final cookie in req.cookies) {
      print('COOKIE: ${cookie.name} => ${cookie.value}');
    }

    res.write('Hello, user #${req.properties['user']['id']}!');
    return false;
  });

  app.use(() => throw new AngelHttpException.notFound());

  app.logger = new Logger('angel')..onRecord.listen(prettyLog);

  var server = await app.startServer(null, 3000);
  print('http://${server.address.address}:${server.port}');
}

/// Your callback should accept a Google+ user. ;)
///
/// I considered forcing you to handle Google+ users in
/// your serializer, but this approach allows users to
/// sign in with multiple platforms.
callback(_, Person profile) => profile;
