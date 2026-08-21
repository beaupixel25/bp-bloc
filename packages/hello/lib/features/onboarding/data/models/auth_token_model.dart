import 'package:hello/features/onboarding/data/models/user_model.dart';
import 'package:hello/features/onboarding/domain/dtos/auth_token.dart';
import 'package:json_annotation/json_annotation.dart';

part 'auth_token_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class AuthTokenModel extends AuthToken {
      
  const AuthTokenModel({
    required this.userModel,
    required super.expiresAt,
  }) : super(user: userModel);

  factory AuthTokenModel.fromJson(Map<String, dynamic> json) =>
      _$AuthTokenModelFromJson(json);

  @JsonKey(name: 'user')
  final UserModel userModel;
  Map<String, dynamic> toJson() => _$AuthTokenModelToJson(this);
}
