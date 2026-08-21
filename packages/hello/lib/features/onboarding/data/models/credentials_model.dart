import 'package:hello/features/onboarding/domain/dtos/credentials.dart';
import 'package:json_annotation/json_annotation.dart';

part 'credentials_model.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, createFactory: false)
class CredentialsModel extends Credentials {
  CredentialsModel({
    required super.email,
    required super.password,
  });

  Map<String, dynamic> toJson() => _$CredentialsModelToJson(this);
}
