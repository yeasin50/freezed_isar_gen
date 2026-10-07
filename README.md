# Generate Isar Classes from Freezed Classes

The approach is to keep the **domain classes** as the source of truth and
generate the corresponding **Isar classes** from them.

The generated Isar classes are intentionally meant to be a starting point.
You can then modify or reconfigure them by hand to fit your application's persistence requirements.

This is particularly useful when migrating an existing application to a **local-first architecture** and
using [Isar CE](https://isar-community.dev/v3/tutorials/quickstart.html)as the local database.

## setup

1. add dependencies into your `pubspec.yaml`

```yaml
environment:
  sdk: ^3.13.4

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8

  build_runner: ^2.16.1
  freezed: ^4.0.2
  isar_community: ^3.3.2

dev_dependencies:
  flutter_test:
    sdk: flutter

  flutter_lints: ^6.0.0
  freezed_isar_gen:
    git:
      url: https://github.com/yeasin50/freezed_isar_gen.git

flutter:
  uses-material-design: true
```

2. Enable the generator

The generator is disabled by default. Enable it in your project's `build.yaml` when you need to generate the Isar classes:

```yaml
targets:
  $default:
    builders:
      freezed_isar_gen:
        enabled: true # use false when  you like to skip it
```

Then run:

```cmd
dart run build_runner build
```

## Monorepo / Split Domain Classes

If your domain classes are split across different directories, configure the input directories and output location in `build.yaml`:

```yaml
targets:
  $default:
    builders:
      freezed_isar_gen:
        enabled: true
        options:
          input_dirs: # TODO:
            - folder_a
            - folder_b
          output_dir: lib/generated/isar
```

This allows the generator to scan multiple directories and keep the generated Isar classes in a dedicated location.

## example

`user.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:isar_community/isar.dart';

import 'package:freezed_isar_gen/freezed_isar_gen.dart';

part 'user.freezed.dart';

@GenerateIsar()
@freezed
abstract class User with _$User {
  const factory User({
    required String id,
    required String name,
    String? email,
    @Enumerated(.name) UserStatus? status,
    @IsarEmbedded() Profile? profile,

    List<String>? tags,

    @IsarEmbedded() List<Profile>? profiles,
  }) = _User;
}

enum UserStatus { active, inactive }

@freezed
abstract class Profile with _$Profile {
  const factory Profile({required String avatar}) = _Profile;
}
```

This will generate freezed and `user.isar.dart`

```dart
// GENERATED CODE

import 'package:isar_community/isar.dart';

import 'package:test_isar_class_gen/user.dart';

part 'user.g.dart';

@collection
class UserIsar {
  late String id;
  late String name;
  String? email;
  @Enumerated(EnumType.name)
  UserStatus? status;
  ProfileIsar? profile;
  List<String>? tags;
  List<ProfileIsar>? profiles;
}

@embedded
class ProfileIsar {
  late String avatar;
}
```
