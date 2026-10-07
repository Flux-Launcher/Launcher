import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:flux_launcher_gui/globals.dart';
import 'package:flux_launcher_gui/utils/skinmodel/skin_utils.dart';
import 'package:simple_3d/simple_3d.dart';
import 'package:simple_3d_renderer/simple_3d_renderer.dart';
import 'package:util_simple_3d/util_simple_3d.dart';

class ThreeDimensionalViewer {
  static List<Sp3dObj> objs = [];
  static Sp3dWorld world = Sp3dWorld(objs);
  static bool isLoaded = false;

  static void setupUV(bool isSlimSkin) {
    int yaw = 0;
    int pitch = 0;

    loadPlayerHead(yaw, pitch);
    loadPlayerChest(yaw, pitch);
    loadPlayerLegs(yaw, pitch);
    loadPlayerArms(yaw, pitch, Globals.getAccount()!.isSlimSkin);
  }

  static void texturizePlayerModel() async {
    final rawSkin = await getImageBytes(SkinUtils.buildSkinModelImageProvider());
    final img.Image? originalSkin = img.decodeImage(rawSkin);

    texturizePlayerHead(originalSkin);
    texturizePlayerChest(originalSkin);
    texturizePlayerLegs(originalSkin);
    texturizePlayerArms(originalSkin, Globals.getAccount()!.isSlimSkin);
    world = Sp3dWorld(objs);
    world.initImages();
  }

  static void loadPlayerHead(dynamic yaw, dynamic pitch) {
    Sp3dObj testa = UtilSp3dGeometry.cube(128, 128, 128, 1, 1, 1);
    updateCube(testa, Sp3dV3D(0, 160, -64), yaw, pitch);
    testa.materials.add(Sp3dMaterial(Colors.green, true, 0.0, Colors.green));
    testa.materials.add(Sp3dMaterial(Colors.red, true, 0.0, Colors.red));
    testa.materials.add(Sp3dMaterial(Colors.blue, true, 0.0, Colors.blue));
    testa.materials.add(Sp3dMaterial(Colors.yellow, true, 0.0, Colors.yellow));
    testa.materials.add(Sp3dMaterial(Colors.purple, true, 0.0, Colors.purple));
    testa.materials.add(Sp3dMaterial(Colors.teal, true, 0.0, Colors.teal));
    for (int i = 0; i < 6; i++) testa.fragments[0].faces[i].materialIndex = i + 1;
    testa.materials[0] = FSp3dMaterial.white;
    objs.add(testa);
  }

  static void loadPlayerChest(dynamic yaw, dynamic pitch) {
    Sp3dObj busto = UtilSp3dGeometry.cube(128, 192, 64, 1, 1, 1);
    updateCube(busto, Sp3dV3D(0, 0, -32), yaw, pitch);
    busto.materials.add(Sp3dMaterial(Colors.lightGreen, true, 0.0, Colors.lightGreen));
    busto.materials.add(Sp3dMaterial(Colors.redAccent, true, 0.0, Colors.redAccent));
    busto.materials.add(Sp3dMaterial(Colors.lightBlue, true, 0.0, Colors.lightBlue));
    busto.materials.add(Sp3dMaterial(Colors.yellowAccent, true, 0.0, Colors.yellowAccent));
    busto.materials.add(Sp3dMaterial(Colors.purpleAccent, true, 0.0, Colors.purpleAccent));
    busto.materials.add(Sp3dMaterial(Colors.tealAccent, true, 0.0, Colors.tealAccent));
    for (int i = 0; i < 6; i++) busto.fragments[0].faces[i].materialIndex = i + 1;
    busto.materials[0] = FSp3dMaterial.white;
    objs.add(busto);
  }

  static void loadPlayerLegs(dynamic yaw, dynamic pitch) {
    Sp3dObj leftleg = UtilSp3dGeometry.cube(64, 192, 64, 1, 1, 1);
    updateCube(leftleg, Sp3dV3D(-32, -192, -32), yaw, pitch);
    leftleg.materials.add(Sp3dMaterial(Colors.lightGreenAccent, true, 0.0, Colors.lightGreenAccent));
    leftleg.materials.add(Sp3dMaterial(const Color(0xffbe0000), true, 0.0, const Color(0xffbe0000)));
    leftleg.materials.add(Sp3dMaterial(const Color(0xff2f2fff), true, 0.0, const Color(0xff2f2fff)));
    leftleg.materials.add(Sp3dMaterial(const Color(0xffffd300), true, 0.0, const Color(0xffffd300)));
    leftleg.materials.add(Sp3dMaterial(const Color(0xff931089), true, 0.0, const Color(0xff931089)));
    leftleg.materials.add(Sp3dMaterial(const Color(0xff00ffb2), true, 0.0, const Color(0xff00ffb2)));
    for (int i = 0; i < 6; i++) leftleg.fragments[0].faces[i].materialIndex = i + 1;
    leftleg.materials[0] = FSp3dMaterial.white;
    objs.add(leftleg);

    Sp3dObj rightleg = UtilSp3dGeometry.cube(64, 192, 64, 1, 1, 1);
    updateCube(rightleg, Sp3dV3D(32, -192, -32), yaw, pitch);
    rightleg.materials.add(Sp3dMaterial(const Color(0xff06dc4b), true, 0.0, const Color(0xff06dc4b)));
    rightleg.materials.add(Sp3dMaterial(const Color(0xffbd0606), true, 0.0, const Color(0xffbd0606)));
    rightleg.materials.add(Sp3dMaterial(const Color(0xff2929ee), true, 0.0, const Color(0xff2929ee)));
    rightleg.materials.add(Sp3dMaterial(const Color(0xffe8c51c), true, 0.0, const Color(0xffe8c51c)));
    rightleg.materials.add(Sp3dMaterial(const Color(0xff9b1191), true, 0.0, const Color(0xff9b1191)));
    rightleg.materials.add(Sp3dMaterial(const Color(0xff12d99c), true, 0.0, const Color(0xff12d99c)));
    for (int i = 0; i < 6; i++) rightleg.fragments[0].faces[i].materialIndex = i + 1;
    rightleg.materials[0] = FSp3dMaterial.white;
    objs.add(rightleg);
  }

  static void loadPlayerArms(dynamic yaw, dynamic pitch, bool isSlimSkin) {
    Sp3dObj leftarm = UtilSp3dGeometry.cube(isSlimSkin ? 48 : 64, 192, 64, 1, 1, 1);
    updateCube(leftarm, Sp3dV3D(isSlimSkin ? -88 : -96, 0, -32), yaw, pitch);
    leftarm.materials.add(Sp3dMaterial(const Color(0xff36ce14), true, 0.0, const Color(0xff36ce14)));
    leftarm.materials.add(Sp3dMaterial(const Color(0xffd73232), true, 0.0, const Color(0xffd73232)));
    leftarm.materials.add(Sp3dMaterial(const Color(0xff324dd7), true, 0.0, const Color(0xff324dd7)));
    leftarm.materials.add(Sp3dMaterial(const Color(0xffd7c932), true, 0.0, const Color(0xffd7c932)));
    leftarm.materials.add(Sp3dMaterial(const Color(0xffb332d7), true, 0.0, const Color(0xffb332d7)));
    leftarm.materials.add(Sp3dMaterial(const Color(0xff1fbb7f), true, 0.0, const Color(0xff1fbb7f)));
    for (int i = 0; i < 6; i++) leftarm.fragments[0].faces[i].materialIndex = i + 1;
    leftarm.materials[0] = FSp3dMaterial.white;
    objs.add(leftarm);

    Sp3dObj rightarm = UtilSp3dGeometry.cube(isSlimSkin ? 48 : 64, 192, 64, 1, 1, 1);
    updateCube(rightarm, Sp3dV3D(isSlimSkin ? 88 : 96, 0, -32), yaw, pitch);
    rightarm.materials.add(Sp3dMaterial(const Color(0xff35c416), true, 0.0, const Color(0xff35c416)));
    rightarm.materials.add(Sp3dMaterial(const Color(0xffbb2323), true, 0.0, const Color(0xffbb2323)));
    rightarm.materials.add(Sp3dMaterial(const Color(0xff2e47c7), true, 0.0, const Color(0xff2e47c7)));
    rightarm.materials.add(Sp3dMaterial(const Color(0xffc5b82a), true, 0.0, const Color(0xffc5b82a)));
    rightarm.materials.add(Sp3dMaterial(const Color(0xffa131c0), true, 0.0, const Color(0xffa131c0)));
    rightarm.materials.add(Sp3dMaterial(const Color(0xff159865), true, 0.0, const Color(0xff159865)));
    for (int i = 0; i < 6; i++) rightarm.fragments[0].faces[i].materialIndex = i + 1;
    rightarm.materials[0] = FSp3dMaterial.white;
    objs.add(rightarm);
  }

  static void texturizePlayerHead(dynamic originalSkin) async {
    objs[0].images.add(Uint8List.fromList(img.encodePng(img.copyCrop(originalSkin!, x: 8, y: 8, width: 8, height: 8))));
    objs[0].images.add(Uint8List.fromList(img.encodePng(img.copyCrop(originalSkin, x: 24, y: 8, width: 8, height: 8))));
    objs[0].images.add(Uint8List.fromList(img.encodePng(img.copyCrop(originalSkin, x: 8, y: 0, width: 8, height: 8))));
    objs[0].images.add(Uint8List.fromList(img.encodePng(img.copyCrop(originalSkin, x: 0, y: 8, width: 8, height: 8))));
    objs[0].images.add(Uint8List.fromList(img.encodePng(img.copyCrop(originalSkin, x: 16, y: 0, width: 8, height: 8))));
    objs[0].images.add(Uint8List.fromList(img.encodePng(img.copyCrop(originalSkin, x: 16, y: 8, width: 8, height: 8))));

    for (int i = 0; i < 6; i++) objs[0].materials[i + 1].imageIndex = i;
  }

  static void texturizePlayerChest(dynamic originalSkin) async {
    objs[1].images.add(Uint8List.fromList(img.encodePng(img.copyCrop(originalSkin, x: 20, y: 20, width: 8, height: 12))));
    objs[1].images.add(Uint8List.fromList(img.encodePng(img.copyCrop(originalSkin, x: 32, y: 20, width: 8, height: 12))));
    objs[1].images.add(Uint8List.fromList(img.encodePng(img.copyCrop(originalSkin, x: 20, y: 16, width: 8, height: 4))));
    objs[1].images.add(Uint8List.fromList(img.encodePng(img.copyCrop(originalSkin, x: 16, y: 20, width: 4, height: 12))));
    objs[1].images.add(Uint8List.fromList(img.encodePng(img.copyCrop(originalSkin, x: 28, y: 16, width: 8, height: 4))));
    objs[1].images.add(Uint8List.fromList(img.encodePng(img.copyCrop(originalSkin, x: 28, y: 20, width: 4, height: 12))));

    for (int i = 0; i < 6; i++) objs[1].materials[i + 1].imageIndex = i;
  }

  static void texturizePlayerLegs(dynamic originalSkin) async {

    img.Image RightLegAvanti = img.copyCrop(originalSkin, x: 4, y: 20, width: 4, height: 12);
    img.flipHorizontal(RightLegAvanti);
    img.Image RightLegDietro = img.copyCrop(originalSkin, x: 12, y: 20, width: 4, height: 12);
    img.flipHorizontal(RightLegDietro);
    img.Image RightLegSopra = img.copyCrop(originalSkin, x: 4, y: 16, width: 4, height: 4);
    img.flipHorizontal(RightLegSopra);
    img.Image RightLegSinistra = img.copyCrop(originalSkin, x: 8, y: 20, width: 4, height: 12);
    img.flipHorizontal(RightLegSinistra);
    img.Image RightLegSotto = img.copyCrop(originalSkin, x: 8, y: 16, width: 4, height: 4);
    img.flipHorizontal(RightLegSotto);
    img.Image RightLegDestra = img.copyCrop(originalSkin, x: 0, y: 20, width: 4, height: 12);
    img.flipHorizontal(RightLegDestra);

    objs[2].images.add(Uint8List.fromList(img.encodePng(img.copyCrop(originalSkin, x: 4, y: 20, width: 4, height: 12))));
    objs[2].images.add(Uint8List.fromList(img.encodePng(img.copyCrop(originalSkin, x: 12, y: 20, width: 4, height: 12))));
    objs[2].images.add(Uint8List.fromList(img.encodePng(img.copyCrop(originalSkin, x: 4, y: 16, width: 4, height: 4))));
    objs[2].images.add(Uint8List.fromList(img.encodePng(img.copyCrop(originalSkin, x: 0, y: 20, width: 4, height: 12))));
    objs[2].images.add(Uint8List.fromList(img.encodePng(img.copyCrop(originalSkin, x: 8, y: 16, width: 4, height: 4))));
    objs[2].images.add(Uint8List.fromList(img.encodePng(img.copyCrop(originalSkin, x: 8, y: 20, width: 4, height: 12))));

    objs[3].images.add(Uint8List.fromList(img.encodePng(RightLegAvanti)));
    objs[3].images.add(Uint8List.fromList(img.encodePng(RightLegDietro)));
    objs[3].images.add(Uint8List.fromList(img.encodePng(RightLegSopra)));
    objs[3].images.add(Uint8List.fromList(img.encodePng(RightLegSinistra)));
    objs[3].images.add(Uint8List.fromList(img.encodePng(RightLegSotto)));
    objs[3].images.add(Uint8List.fromList(img.encodePng(RightLegDestra)));

    for (int i = 0; i < 6; i++) objs[2].materials[i + 1].imageIndex = i;
    for (int i = 0; i < 6; i++) objs[3].materials[i + 1].imageIndex = i;
  }

  static void texturizePlayerArms(dynamic originalSkin, bool isSlimSkin) async {

    img.Image RightArmAvanti = img.copyCrop(originalSkin, x: 44, y: 20, width: isSlimSkin ? 3 : 4, height: 12);
    img.flipHorizontal(RightArmAvanti);
    img.Image RightArmDietro = img.copyCrop(originalSkin, x: 52, y: 20, width: isSlimSkin ? 3 : 4, height: 12);
    img.flipHorizontal(RightArmDietro);
    img.Image RightArmSopra = img.copyCrop(originalSkin, x: 44, y: 16, width: isSlimSkin ? 3 : 4, height: 4);
    img.flipHorizontal(RightArmSopra);
    img.Image RightArmSinistra = img.copyCrop(originalSkin, x: 48, y: 20, width: 4, height: 12);
    img.flipHorizontal(RightArmSinistra);
    img.Image RightArmSotto = img.copyCrop(originalSkin, x: 48, y: 16, width: isSlimSkin ? 3 : 4, height: 4);
    img.flipHorizontal(RightArmSotto);
    img.Image RightArmDestra = img.copyCrop(originalSkin, x: 40, y: 20, width: 4, height: 12);
    img.flipHorizontal(RightArmDestra);

    objs[4].images.add(Uint8List.fromList(img.encodePng(img.copyCrop(originalSkin, x: 44, y: 20, width: isSlimSkin ? 3 : 4, height: 12))));
    objs[4].images.add(Uint8List.fromList(img.encodePng(img.copyCrop(originalSkin, x: 52, y: 20, width: isSlimSkin ? 3 : 4, height: 12))));
    objs[4].images.add(Uint8List.fromList(img.encodePng(img.copyCrop(originalSkin, x: 44, y: 16, width: isSlimSkin ? 3 : 4, height: 4))));
    objs[4].images.add(Uint8List.fromList(img.encodePng(img.copyCrop(originalSkin, x: 40, y: 20, width: 4, height: 12))));
    objs[4].images.add(Uint8List.fromList(img.encodePng(img.copyCrop(originalSkin, x: 48, y: 16, width: isSlimSkin ? 3 : 4, height: 4))));
    objs[4].images.add(Uint8List.fromList(img.encodePng(img.copyCrop(originalSkin, x: 48, y: 20, width: 4, height: 12))));

    objs[5].images.add(Uint8List.fromList(img.encodePng(RightArmAvanti)));
    objs[5].images.add(Uint8List.fromList(img.encodePng(RightArmDietro)));
    objs[5].images.add(Uint8List.fromList(img.encodePng(RightArmSopra)));
    objs[5].images.add(Uint8List.fromList(img.encodePng(RightArmSinistra)));
    objs[5].images.add(Uint8List.fromList(img.encodePng(RightArmSotto)));
    objs[5].images.add(Uint8List.fromList(img.encodePng(RightArmDestra)));

    for (int i = 0; i < 6; i++) objs[4].materials[i + 1].imageIndex = i;
    for (int i = 0; i < 6; i++) objs[5].materials[i + 1].imageIndex = i;
  }

  static void updateCube(Sp3dObj obj, Sp3dV3D position, int yaw, int pitch) {
    obj.move(position);
    obj.rotateBy(
      Sp3dV3D(0, 0, 0),
      Sp3dV3D(0, 1, 0).nor(),
      yaw * Sp3dConstantValues.toRadian,
    );
    obj.rotateBy(
      Sp3dV3D(0, 0, 0),
      Sp3dV3D(1, 0, 0).nor(),
      pitch * Sp3dConstantValues.toRadian,
    );
  }

  static Future<Uint8List> getImageBytes(ImageProvider imageProvider) async {
    final completer = Completer<Uint8List>();
    final imageStream = imageProvider.resolve(ImageConfiguration.empty);

    imageStream.addListener(ImageStreamListener((info, _) async {
      final byteData = await info.image.toByteData(format: ImageByteFormat.png);
      if (byteData != null) {
        final uint8List = byteData.buffer.asUint8List();
        completer.complete(uint8List);
      }
    }));

    return completer.future;
  }
}
