import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

class EditImageWidget extends StatefulWidget {
  const EditImageWidget({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => EditImageWidgetState();
}

class EditImageWidgetState extends State<EditImageWidget> {
  List<Offset?> _pencilPoints = <Offset>[];
  GlobalKey previewContainer = GlobalKey();

  static const int DRAW_PENCIL = 1;
  int drawType = DRAW_PENCIL;
  String imgUrl = "https://picsum.photos/200/300";

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: InkWell(
          child: Stack(
            children: <Widget>[
              RepaintBoundary(
                key: previewContainer,
                child: Stack(fit: StackFit.expand, children: <Widget>[
                  Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                          image: NetworkImage(imgUrl), fit: BoxFit.fill),
                    ),
                  ),
                  GestureDetector(
                    onTapDown: (TapDownDetails details) {
                      //print("OnTapDown called ");
                    },
                    onTapUp: (TapUpDetails details) {
                      RenderBox object =
                          context.findRenderObject() as RenderBox;
                      Offset _localPosition =
                          object.globalToLocal(details.globalPosition);
                    },
                    onPanUpdate: (DragUpdateDetails dragDetails) {
                      if (drawType == DRAW_PENCIL) {
                        RenderBox object =
                            context.findRenderObject() as RenderBox;
                        Offset _localPosition =
                            object.globalToLocal(dragDetails.globalPosition);

                        _pencilPoints = List.from(_pencilPoints);

                        setState(() {
                          _pencilPoints.add(_localPosition);
                        });
                      }
                    },
                    onPanEnd: (DragEndDetails details) {
                      if (drawType == DRAW_PENCIL) {
                        _pencilPoints.add(null);
                        /*  setState(() {

                        });*/
                      }
                    },
                    child: CustomPaint(
                      painter: PencilPainter(
                        points: _pencilPoints,
                      ),
                      child: Container(),
                    ),
                  ),
                ]),
              ),
              Align(
                alignment: Alignment.topRight,
                child: MaterialButton(
                  onPressed: () {
                    _takeScreenShot();
                    _onClearClicked();
                  },
                  child: const Text(
                    "Save",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _onClearClicked() {
    // //print('Clear Clicked');
    _pencilPoints.clear();
    _pencilPoints = <
        Offset>[]; //Adding this clears on single click... this was not happening before

    setState(() {
      _pencilPoints.clear();
    });
  }

  _takeScreenShot() async {
    try {
      RenderRepaintBoundary boundary = previewContainer.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      double pixelRatio = 3;
      ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

     await ImageGallerySaver.saveImage(pngBytes,
          quality: 100,
          name: "${DateTime.now().millisecondsSinceEpoch}test.png");
      setState(() {});
    } catch (e) {
      debugPrint("Exception while taking screenshot $e");
    }
  }
}

class PencilPainter extends CustomPainter {
  List<Offset?> points;

  ImageInfo? imageInfo;

  PencilPainter({
    required this.points,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint =  Paint()
      ..color = const Color(0xFFFF0000)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    paint.style = PaintingStyle.stroke;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }

      if (i > 0 &&
          points[i - 1] == null &&
          points[i] != null &&
          points[i + 1] == null) {
        canvas.drawCircle(points[i]!, 3.0 / 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(PencilPainter oldDelegate) => oldDelegate.points != points;
}
