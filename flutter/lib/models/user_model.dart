import 'package:flutter_hbb/common/hbbs/hbbs.dart';
import 'package:get/get.dart';

import '../common.dart';
import 'model.dart';
import 'platform_model.dart';

bool refreshingUser = false;

class UserModel {
  final RxString userName = ''.obs;
  final RxString displayName = ''.obs;
  final RxString avatar = ''.obs;
  final RxBool isAdmin = false.obs;
  final RxString networkError = ''.obs;
  final RxBool networkErrorFromServer = false.obs;
  bool get isLogin => false;
  String get displayNameOrUserName => '';
  String get accountLabelWithHandle => '';

  WeakReference<FFI> parent;

  UserModel(this.parent);

  void refreshCurrentUser() async {
    await reset();
  }

  static Map<String, dynamic>? getLocalUserInfo() => null;

  Future<void> reset({bool resetOther = false}) async {
    await bind.mainSetLocalOption(key: 'access_token', value: '');
    await bind.mainSetLocalOption(key: 'user_info', value: '');
    if (resetOther) {
      await gFFI.abModel.reset();
      await gFFI.groupModel.reset();
    }
    userName.value = '';
    displayName.value = '';
    avatar.value = '';
    isAdmin.value = false;
    networkError.value = '';
    networkErrorFromServer.value = false;
  }

  static Future<void> updateOtherModels() async {}

  Future<void> logOut({String? apiServer}) async {
    await reset(resetOther: true);
  }

  Future<LoginResponse> login(LoginRequest loginRequest) async {
    throw UnsupportedError('Cuenta no disponible en NiSoporte');
  }

  LoginResponse getLoginResponseFromAuthBody(Map<String, dynamic> body) {
    throw UnsupportedError('Cuenta no disponible en NiSoporte');
  }

  static Future<List<dynamic>> queryOidcLoginOptions() async => [];
}
