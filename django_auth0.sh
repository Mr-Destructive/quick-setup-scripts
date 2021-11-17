#!/usr/bin/env bash

mkdir $1
cd $1
pip install virtualenv
virtualenv venv
source venv/Scripts/activate

pip install django
django-admin startproject $1 .

cat << EOF >> requirements.txt
social-auth-app-django~=3.1 
python-jose~=3.0 
python-dotenv~=0.9
EOF

pip install -r requirements.txt

pip freeze > requirements.txt

python manage.py startapp auth0login

touch auth0login/urls.py
mkdir auth0login/templates
touch auth0login/templates/index.html
touch auth0login/templates/dashboard.html

sed -i '40 i \    '"'"'social_django'"'"',' $1/settings.py
sed -i '41 i \    '"'"'auth0login'"'"',' $1/settings.py
sed -i '21 i \    path('"''"', include('"'auth0login.urls'"')),' $1/urls.py
sed -i '17 s/$/, include/' $1/urls.py 

cat << EOF >> $1/settings.py
SOCIAL_AUTH_TRAILING_SLASH = False  # Remove trailing slash from routes
SOCIAL_AUTH_AUTH0_DOMAIN = 'YOUR_DOMAIN'
SOCIAL_AUTH_AUTH0_KEY = 'YOUR_CLIENT_ID'
SOCIAL_AUTH_AUTH0_SECRET = 'YOUR_CLIENT_SECRET'
EOF

cat << EOF >> $1/settings.py 
SOCIAL_AUTH_AUTH0_SCOPE = [
    'openid',
    'profile',
    'email'
]
EOF

python manage.py migrate

cat << EOF >>auth0login/auth0backend.py

from urllib import request
from jose import jwt
from social_core.backends.oauth import BaseOAuth2


class Auth0(BaseOAuth2):
    """Auth0 OAuth authentication backend"""
    name = 'auth0'
    SCOPE_SEPARATOR = ' '
    ACCESS_TOKEN_METHOD = 'POST'
    REDIRECT_STATE = False
    EXTRA_DATA = [
        ('picture', 'picture'),
        ('email', 'email')
    ]

    def authorization_url(self):
        return 'https://' + self.setting('DOMAIN') + '/authorize'

    def access_token_url(self):
        return 'https://' + self.setting('DOMAIN') + '/oauth/token'

    def get_user_id(self, details, response):
        """Return current user id."""
        return details['user_id']

    def get_user_details(self, response):
        # Obtain JWT and the keys to validate the signature
        id_token = response.get('id_token')
        jwks = request.urlopen('https://' + self.setting('DOMAIN') + '/.well-known/jwks.json')
        issuer = 'https://' + self.setting('DOMAIN') + '/'
        audience = self.setting('KEY')  # CLIENT_ID
        payload = jwt.decode(id_token, jwks.read(), algorithms=['RS256'], audience=audience, issuer=issuer)

        return {'username': payload['nickname'],
                'first_name': payload['name'],
                'picture': payload['picture'],
                'user_id': payload['sub'],
                'email': payload['email']}

EOF

cat << EOF >> $1/settings.py

AUTHENTICATION_BACKENDS = {
    #'YOUR_DJANGO_APP_NAME.auth0backend.Auth0',
    'django.contrib.auth.backends.ModelBackend'
}

EOF

cat << EOF >> $1/settings.py

LOGIN_URL = '/login/auth0'
LOGIN_REDIRECT_URL = '/dashboard'
EOF

cat > auth0login/views.py<<EOF

from django.shortcuts import render, redirect
from django.contrib.auth.decorators import login_required
from django.contrib.auth import logout as log_out
from django.conf import settings
from django.http import HttpResponseRedirect
from urllib.parse import urlencode
import json

def index(request):
    user = request.user
    if user.is_authenticated:
        return redirect(dashboard)
    else:
        return render(request, 'index.html')


@login_required
def dashboard(request):
    user = request.user
    auth0user = user.social_auth.get(provider='auth0')
    userdata = {
        'user_id': auth0user.uid,
        'name': user.first_name,
        'picture': auth0user.extra_data['picture'],
        'email': auth0user.extra_data['email'],
    }

    return render(request, 'dashboard.html', {
        'auth0User': auth0user,
        'userdata': json.dumps(userdata, indent=4)
    })

def logout(request):
    log_out(request)
    return_to = urlencode({'returnTo': request.build_absolute_uri('/')})
    logout_url = 'https://%s/v2/logout?client_id=%s&%s' % \
                 (settings.SOCIAL_AUTH_AUTH0_DOMAIN, settings.SOCIAL_AUTH_AUTH0_KEY, return_to)
    return HttpResponseRedirect(logout_url)

EOF

cat << EOF >> auth0login/templates/index.html

<div class="login-box auth0-box before">
    <img src="https://i.cloudup.com/StzWWrY34s.png" />
    <h3>Auth0 Example</h3>
    <p>Zero friction identity infrastructure, built for developers</p>
    <a class="btn btn-primary btn-lg btn-login btn-block" href="/login/auth0">Log In</a>
</div>
EOF

cat << EOF >> auth0login/templates/dashboard.html

<div class="logged-in-box auth0-box logged-in">
    <h1 id="logo"><img src="//cdn.auth0.com/samples/auth0_logo_final_blue_RGB.png" /></h1>
    <img class="avatar" src="{{ auth0User.extra_data.picture }}"/>
    <h2>Welcome {{ user.username }}</h2>
    <pre>{{ userdata }}</pre>
</div>
EOF

cat << EOF >> auth0login/urls.py
from django.urls import path, include
from . import views

urlpatterns = [
    path('', views.index),
    path('dashboard', views.dashboard),
    path('logout', views.logout),
    path('', include('django.contrib.auth.urls')),
    path('', include('social_django.urls')),
]

EOF

python manage.py makemigrations
python manage.py migrate
