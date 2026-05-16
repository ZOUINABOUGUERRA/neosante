// test/widget_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neosante/main.dart';

void main() {
  // ✅ اختبار بسيط للتحقق من أن التطبيق يعمل
  testWidgets('NéoSanté app launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const NeoSanteApp());
    
    // Verify that the app doesn't crash
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  // ✅ اختبار للتحقق من وجود عنوان التطبيق
  testWidgets('App has correct title', (WidgetTester tester) async {
    await tester.pumpWidget(const NeoSanteApp());
    
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.title, 'NéoSanté');
  });

  // ✅ اختبار للتحقق من وجود شاشة تسجيل الدخول
  testWidgets('Login screen is initially shown', (WidgetTester tester) async {
    await tester.pumpWidget(const NeoSanteApp());
    
    // انتظر حتى يتم تحميل التطبيق
    await tester.pumpAndSettle();
    
    // تحقق من وجود عناصر شاشة تسجيل الدخول
    expect(find.text('NéoSanté'), findsOneWidget);
    expect(find.text('Système Intelligent de Néonatologie'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });

  // ✅ اختبار للتحقق من اختيار دور المستخدم
  testWidgets('User can select role', (WidgetTester tester) async {
    await tester.pumpWidget(const NeoSanteApp());
    await tester.pumpAndSettle();
    
    // التحقق من وجود أزرار اختيار الدور
    expect(find.text('Sage-Femme'), findsOneWidget);
    expect(find.text('Administrateur'), findsOneWidget);
  });

  // ✅ اختبار للتحقق من إدخال البريد الإلكتروني
  testWidgets('Email field accepts input', (WidgetTester tester) async {
    await tester.pumpWidget(const NeoSanteApp());
    await tester.pumpAndSettle();
    
    // البحث عن حقل البريد الإلكتروني
    final emailField = find.byType(TextField).first;
    expect(emailField, findsOneWidget);
    
    // إدخال نص في الحقل
    await tester.enterText(emailField, 'test@example.com');
    await tester.pump();
    
    // التحقق من أن النص تم إدخاله
    expect(find.text('test@example.com'), findsOneWidget);
  });

  // ✅ اختبار للتحقق من إدخال كلمة المرور
  testWidgets('Password field accepts input', (WidgetTester tester) async {
    await tester.pumpWidget(const NeoSanteApp());
    await tester.pumpAndSettle();
    
    // البحث عن حقل كلمة المرور (عادةً الثاني)
    final passwordFields = find.byType(TextField);
    expect(passwordFields, findsAtLeastNWidgets(2));
    
    // إدخال نص في حقل كلمة المرور
    await tester.enterText(passwordFields.last, 'password123');
    await tester.pump();
    
    // التحقق من أن النص تم إدخاله
    expect(find.text('password123'), findsOneWidget);
  });
}
