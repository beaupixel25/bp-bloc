import 'package:hello/features/onboarding/domain/dtos/email_signup.dart';
import 'package:json_annotation/json_annotation.dart';

part 'email_signup_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, createFactory: false)
class EmailSignupModel extends EmailSignup {
  EmailSignupModel({
    required super.email,
    required super.password,
  });

  Map<String, dynamic> toJson() => _$EmailSignupModelToJson(this);
}
