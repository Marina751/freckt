import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:freckt_fretista/utils/consts.dart';

import '../models/fretista.model.dart';

class Conta extends StatefulWidget {
  final model = FretistaModel();

  @override
  _ContaState createState() => _ContaState();
}

class _ContaState extends State<Conta> {
  Text textWithColorTheme(String string) {
    return new Text(
      string,
      style: TextStyle(color: Consts.frecktThemeColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Consts.frecktThemeColor,
        leading: IconButton(
          color: Colors.white,
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Conta'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.only(top: 10.0, bottom: 50.0),
              alignment: Alignment.center,
              child: Stack(
                alignment: AlignmentDirectional.bottomEnd,
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(widget.model.getPhotoUrl),
                    backgroundColor: Colors.black12,
                    radius: 100.0,
                  ),
                  LimitedBox(
                    child: CircleAvatar(
                      backgroundColor: Consts.frecktThemeColor,
                      radius: 30.0,
                      child: IconButton(
                        splashRadius: 10.0,
                        icon: Icon(
                          Icons.edit,
                          color: Colors.white,
                        ),
                        onPressed: () {}, //showBottomSheet,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              title: textWithColorTheme('Nome'),
              subtitle: Text(widget.model.getUserName),
            ),
            ListTile(
              title: textWithColorTheme('Telefone'),
              subtitle: Text(widget.model.getUserPhone),
            ),
            ListTile(
              title: textWithColorTheme('E-mail'),
              subtitle: Text(widget.model.getUserEmail),
            ),
          ],
        ),
      ),
    );
  }
}
