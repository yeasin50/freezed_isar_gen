# Generate Isar Classes from Freezed Classes

> This is for an old _specific_ project. You may fork it and increase the dependencies.
> Or maybe I’ll create some versions if I need it again.
> The way I use it is to create a separate branch and cherry-pick only those generated files, not the domain.
> This will keep the boring tasks away, and I’ll review and tweak things as needed.
> I had no intention of making this public for issues.

The approach is to keep the **domain classes** as the source of truth and
generate the corresponding **Isar classes** from them.

The generated Isar classes are intentionally meant to be a starting point.
You can then modify or reconfigure them by hand to fit your application's persistence requirements.

This is particularly useful when migrating an existing application to a **local-first architecture** and
using [Isar CE](https://isar-community.dev/v3/tutorials/quickstart.html)as the local database.

## setup

1. add dependencies into your `pubspec.yaml`

```yaml
freezed_isar_gen:
  git:
    url: https://github.com/yeasin50/freezed_isar_gen.git
```

<details> <summary> in case you want </summary>

```yaml
name: domain
description: "Pure entity of the app class"
version: 0.0.1
resolution: workspace
homepage:

environment:
sdk: ^3.10.1
flutter: ">=1.17.0"

dependencies:
flutter:
sdk: flutter
http: ^1.6.0
freezed_annotation: ^3.1.0
json_annotation: ^4.9.0

core:
path: ./../core

dev_dependencies:
flutter_test:
sdk: flutter

build_runner: any
slang_build_runner: any

flutter_lints: ^5.0.0
freezed: ^3.2.3
json_serializable: ^6.7.1

freezed_isar_gen:
git:
url: https://github.com/yeasin50/freezed_isar_gen.git
isar_community: ^3.3.2
```

</details>

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

@IsarGenerate()
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
