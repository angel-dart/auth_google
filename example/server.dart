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

  // Your serializer should accept a Google+ user. ;)
  auth.serializer = (Person user) async {
    // ...
    print('User: ${user.toJson()}');
    return user.id;
  };

  auth.deserializer = (id) async {
    return {'id': id};
  };

  await app.configure(auth);

  app.get('/', (res) => res.redirect('/index.html', code: 302));

  app.get('/auth/google', auth.authenticate('google'));

  app.get(
      '/auth/google/callback',
      auth.authenticate(
          'google',
          new AngelAuthOptions(
              successRedirect: '/home', failureRedirect: '/login?error=1')));

  app.get('/home', (req, res) {
    res.write('Hello, user #${req.user['id']}!');
    return false;
  });

  app.all('*', () {
    throw new AngelHttpException.NotFound();
  });

  final server = await app.startServer(null, 3000);
  print('Listening at http://${server.address.address}:${server.port}');
}

callback(creds, Person profile) {
  print('Hello: ${profile.toJson()}');
  return profile.id;
}
