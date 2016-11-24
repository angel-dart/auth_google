# auth_google
angel_auth strategy for Google OAuth2 login.

```dart
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
  
  auth.strategies.add(
      config: new GoogleOauth2Strategy({
        'id': '<your-client-id-here>',
        'secret': '<your-client-secret-here>',
        'redirect_uri': '<your-redirect-uri-here>'
      },
      scopes: scopes));
  
  // Your serializer should accept a Google+ user. ;)
  auth.serializer = (Person user) async {
    // ...
  };
  
  auth.deserializer = app.service('users').read;
  
  app.get('/auth/google', auth.authenticate('google'));
  
  app.get(
    '/auth/google/callback',
    auth.authenticate('google', new AngelAuthOptions(
        successRedirect: '/home',
        failureRedirect: '/login?error=1'
    )));
  
  await app.configure(auth);
  await app.startServer();
}
```