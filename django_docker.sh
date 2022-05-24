# ======================
# From Debian to Web App
# ======================

# This page contains a list of terminal commands that
# create a Django web application with routing, templates
# and user accounts.
#
# You can start from a fresh debian installation. Or with a
# fresh debian container:
#
# docker run -v $(pwd):/var/www --rm -it -p 80:80 debian:11-slim
#  
# You can copy+paste each command to see the application take
# shape or copy the whole page and paste it in one go.
# You can also download it here: https://...

# ======================
# Let's configure Debian
# ======================

# Do not show dialogs during the upgrade
export DEBIAN_FRONTEND=noninteractive
# Update the packages
apt update -y && apt upgrade -y

# ====================
# Let's install Django
# ====================

cd /var/www
apt install -y python3-django
django-admin startproject $1
cd $1
python3 manage.py migrate

# ====================
# Let's install Apache
# ====================

apt install -y apache2
apt install -y libapache2-mod-wsgi-py3

cat << 'EOF' > /etc/apache2/sites-enabled/000-default.conf
ServerName $1.local
WSGIPythonPath /var/www/$1
<VirtualHost *:80>
    WSGIScriptAlias / /var/www/$1/$1/wsgi.py
    <Directory /var/www/$1/$1>
        <Files wsgi.py>
            Require all granted
        </Files>
    </Directory>
</VirtualHost>
EOF

service apache2 start

# Yay, we have a working Django instance!
read -p 'Django is live at 127.0.0.1! Hit enter to continue.'

# ===================
# Let's use templates
# ===================

# $1/ in $1/ is the code dir in Django
cd $1

mkdir templates

cat << 'EOF' > templates/index.html
<h1>Hello World</h1>
EOF

cat << 'EOF' > views.py
from django.shortcuts import render
def index(request):
    return render(request, 'index.html')
EOF

cat << 'EOF' > urls.py
from django.contrib import admin
from django.urls import path
from . import views

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', views.index, name='index'),
]
EOF

cat << 'EOF' >> settings.py
INSTALLED_APPS += ["$1"]
EOF

service apache2 restart

# Yay, we have static site!
read -p 'Serving a static site! Hit enter to continue.'

# =========================
# Let's use a base template
# =========================

# Let's create a base template 
cat << 'EOF' > templates/base.html
<!DOCTYPE html>
<html>
<head>
    <title>Hello World</title>
    <style>
        body {background: #60a060}
    </style>
</head>
<body>{% block content %}{% endblock %}</body>
</html>
EOF

# And use it for the index page:
cat << 'EOF' > templates/index.html
{% extends "base.html" %}
{% block content %}
    <h1>Hello World</h1>
{% endblock %}
EOF

service apache2 restart

# Yay, we have a working base template!
read -p 'The base template is live! Hit enter to continue.'

# =======================
# Let's add user accounts
# =======================
cd ..

# Create a new app called User for Auth
django-admin startapp user

cat << 'EOF' >> $1/settings.py
INSTALLED_APPS += ['user']
EOF

mkdir $1/templates/user

# Apply Auth model migrations to db
python3 manage.py makemigrations
python3 manage.py migrate

# Create a User Registration Form 
# Extends the UserCreationForm
cat << 'EOF' > user/forms.py
from django import forms
from django.contrib.auth.models import User
from django.contrib.auth.forms import UserCreationForm

class UserRegisterForm(UserCreationForm):
    email = forms.EmailField()

    class Meta:
        model= User
        fields = ['username', 'email', 'password1', 'password2']
EOF

# Create some basic views for registration
cat << 'EOF' > user/views.py
from django.shortcuts import render, redirect
from .forms import UserRegisterForm

def index(request):
    return render(request, 'user/index.html')

def register(request):
    if request.method == 'POST':
        form = UserRegisterForm(request.POST)
        if form.is_valid():
            form.save()
            username = form.cleaned_data.get('username')
            return redirect('login')
    else:
        form = UserRegisterForm()
    return render(request, 'user/register.html', {'form': form})

EOF

# Create the URL mappings of Auth
cat << 'EOF' > user/urls.py
from django.urls import path, include
from django.contrib.auth import views as auth_views
from user import views as user_views

urlpatterns = [
    path('', user_views.index, name='auth'),
    path('register/', user_views.register, name='register'),
    path('login/', auth_views.LoginView.as_view(template_name='user/login.html'), name='login'),
    path('logout/',auth_views.LogoutView.as_view(template_name='user/logout.html'), name='logout'),
]
EOF

cat << 'EOF' > $1/urls.py
from django.contrib import admin
from django.urls import path, include
from . import views

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', views.index, name='index'),
    path('auth/', include('user.urls')),
]
EOF

# Create Templates for Authorization
cat << 'EOF' > $1/templates/user/index.html
{% extends 'base.html' %}

{% block content %}
    <a href="{% url 'register' %}"><button>Register</button></a>
    <a href="{% url 'login' %}"><button>Login</button></a>
{% endblock %}

EOF

cat << 'EOF' > $1/templates/user/register.html
{% extends 'base.html' %}

{% block content %}
    <form method="POST">
        {% csrf_token %}
            {{ form.as_p }}
            <button type="submit">Sign Up</button>
    </form>
        <p>
        Already have an Account? <a href="{% url 'login' %}"><button>Log In</button></a>
        </p>
{% endblock %}

EOF

cat << 'EOF' > $1/templates/user/login.html
{% extends 'base.html' %}

{% block  content %}
    <form method="POST">
        {% csrf_token %}
            {{ form.as_p }}
            <button type="submit">Log In</button>
    </form>
        <p>
            Don't have an Account? <a href="{% url 'register' %}"><button>Register</button></a>
        </p>
{% endblock %}

EOF

cat << 'EOF' > $1/templates/user/logout.html
{% extends 'base.html' %}

{% block content %}
        <p>
            Don't have an account?
            <a href="{% url 'register' %}"><button>Register</button></a>
        </p>
        <p>
            Already have an Account?<a href="{% url 'login' %}"><button>Login</button></a>
        </p>
{% endblock %}

EOF

# Create a Login redirect URL route
cat << 'EOF' >> $1/settings.py
LOGIN_REDIRECT_URL = 'index'
EOF


cat << 'EOF' > $1/templates/index.html
{% extends "base.html" %}
{% block content %}
    {% if user.is_authenticated %}
    <h1>Hello, {{ user.username }}!</h1>
    <h3>You are logged in as {{ user.username }} </h3>
    <a href="{% url 'logout' %}"><button>Logout</button></a>
    {% else %}
    <h1>Hello, World!</h1>
    <a href="{% url 'auth' %}"><button>Authorize</button></a>
    {% endif %}
{% endblock %}

EOF

chown www-data:www-data .
chown www-data:www-data db.sqlite3

service apache2 restart
read -p 'Auth configured at 127.0.0.1:8000/auth/ Hit enter to continue. '
