#!/usr/bin/env bash

mkdir $1
cd $1
gradle init

mkdir -p app/src/main/res/values
mkdir app/src/main/res/layout/
mkdir -p app/src/main/java/com/example/user/$1
touch app/build.gradle
touch app/src/main/res/values/styles.xml
touch app/src/main/AndroidManifest.xml
touch app/src/main/java/com/example/user/$1/MainActivity.java
touch app/src/main/res/layout/activity_main.xml

cat << EOF >> build.gradle
buildscript {

    repositories {
        google()
        jcenter()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:3.1.3'
    }
}

allprojects {
    repositories {
        google()
        jcenter()
    }
}

task clean(type: Delete) {
    delete rootProject.buildDir
}
EOF

cat << EOF >> app/build.gradle
apply plugin: 'com.android.application'

android {
    compileSdkVersion 25
    defaultConfig {
        applicationId "com.example.user.$1"
        minSdkVersion 16
        targetSdkVersion 25
        versionCode 1
        versionName "1.0"
    }
    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}

dependencies {
    implementation 'com.android.support.constraint:constraint-layout:1.1.2'
    implementation 'com.android.support:appcompat-v7:25.3.1'
}
EOF

cat << EOF >> app/src/main/res/values/styles.xml
<resources>

    <!-- Base application theme. -->
    <style name="AppTheme" parent="Theme.AppCompat.Light.NoActionBar">
        <!-- Customize your theme here. -->
    </style>

</resources>
EOF

cat << EOF >> app/src/main/AndroidManifest.xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.suer.$1">

    <application
        android:label="Demo App"
        android:theme="@style/AppTheme">

        <activity android:name=".MainActivity">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>

</manifest>
EOF

cat << EOF >> app/src/main/java/com/example/user/$1/MainActivity.java
package com.example.user.$1;

import android.app.Activity;
import android.os.Bundle;

public class MainActivity extends Activity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
    }
}
EOF

cat << EOF >> app/src/main/res/layout/activity_main.xml
<?xml version="1.0" encoding="utf-8"?>
<android.support.constraint.ConstraintLayout xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    tools:context=".MainActivity">

    <TextView
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="Hello World!"
        app:layout_constraintBottom_toBottomOf="parent"
        app:layout_constraintLeft_toLeftOf="parent"
        app:layout_constraintRight_toRightOf="parent"
        app:layout_constraintTop_toTopOf="parent" />

</android.support.constraint.ConstraintLayout>
EOF

# gradle build
# gradle installDebug

