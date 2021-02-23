import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:freckt_fretista/models/fretista.model.dart';
import 'package:freckt_fretista/utils/consts.dart';
import 'package:freckt_fretista/utils/status_frete.dart';
import 'package:freckt_fretista/utils/templates/avatar_template.dart';
import 'package:freckt_fretista/views/chat.dart';
import 'package:freckt_fretista/views/loading.dart';
import 'package:freckt_fretista/views/solicitacao.dart';
import 'package:freckt_fretista/views/something_went_wrong.dart';
import 'package:url_launcher/url_launcher.dart';

class Solicitacoes extends StatefulWidget {
  @override
  _SolicitacoesState createState() => _SolicitacoesState();
}

class _SolicitacoesState extends State<Solicitacoes> {
  final model = FretistaModel();
  final listScrollController = ScrollController();
  final solicitacoes = FirebaseFirestore.instance.collection('solicitacoes');
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isLoading = false;

  Widget noRequests() {
    return Container(
      padding: EdgeInsets.all(10.0),
      child: Center(
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Bem-vindo ao Freckt.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0,
                ),
              ),
              TextSpan(
                text:
                    '\nQuando você tiver solicitações de fretes, elas aparecerão aqui.\n\nPara mais detalhes sobre este app, acesse a ',
              ),
              TextSpan(
                text: 'ajuda.',
                style: TextStyle(color: Colors.blue),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  String _twoDigits(int n) => (n < 10 ? '0$n' : '$n');

  bool _isToday({
    @required int day,
    @required int month,
    @required int year,
  }) {
    final today = DateTime.now();

    return (day == today.day && month == today.month && year == today.year);
  }

  String formatDateTime(DateTime dateTime) {
    int y = dateTime.year;
    int m = dateTime.month;
    int d = dateTime.day;
    String h = _twoDigits(dateTime.hour);
    String min = _twoDigits(dateTime.minute);

    String date = _isToday(day: d, month: m, year: y)
        ? 'hoje'
        : 'em ${_twoDigits(d)}-${_twoDigits(m)}-$y';

    return 'Enviado $date às $h:$min';
  }

  Text statusFrete(int status) {
    Color textColor = Colors.black;
    String text = 'Situação do frete';

    switch (status) {
      case StatusFrete.REJEITADO:
        textColor = Colors.red;
        text = 'Frete rejeitado';
        break;
      case StatusFrete.CANCELADO:
        textColor = Colors.red;
        text = 'Frete cancelado';
        break;
      case StatusFrete.ESPERANDO_RESPOSTA:
        textColor = Colors.orange;
        text = 'Esperando uma resposta sua';
        break;
      case StatusFrete.EM_ANDAMENTO:
        textColor = Colors.green;
        text = 'Frete em andamento';
        break;
      case StatusFrete.CONCLUIDO:
        textColor = Colors.green;
        text = 'Frete concluído';
        break;
      default:
        break;
    }

    return Text(text, style: TextStyle(color: textColor));
  }

  Future<void> _makePhoneCall(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      _scaffoldKey.currentState.showSnackBar(
        SnackBar(content: Text('Ação indisponível')),
      );
    }
  }

  void setStatusFrete({
    @required String campo,
    @required dynamic value,
    @required DocumentReference docRef,
  }) async {
    setState(() {
      _isLoading = true;
    });

    await docRef.update({campo: value});

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _onSetStateFrete(DocumentReference docRef,
      {int newStatus = -1}) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          title: Text(newStatus == StatusFrete.REJEITADO
              ? 'Rejeitar esta solicitação?'
              : 'Apagar esta solicitação?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                newStatus == -1
                    ? setStatusFrete(
                        campo: 'visivelFretista',
                        value: false,
                        docRef: docRef,
                      )
                    : setStatusFrete(
                        campo: 'status',
                        value: newStatus,
                        docRef: docRef,
                      );
                Navigator.pop(context);
              },
              child: Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  Widget bottomItem(Map<String, dynamic> data) {
    int status = data['status'];

    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          (status == StatusFrete.CANCELADO || status == StatusFrete.REJEITADO)
              ? Container()
              : Row(
                  children: [
                    IconButton(
                      color: Color(0xff13786C),
                      icon: Icon(Icons.call_rounded),
                      onPressed: () async {
                        await _makePhoneCall('tel:${data['clientePhone']}');
                      },
                    ),
                    IconButton(
                      color: Color(0xff13786C),
                      icon: Icon(Icons.chat_rounded),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => Chat(
                              clienteId: data['clienteId'],
                              clienteName: data['clienteName'],
                              clientePhotoUrl: data['clientePhotoUrl'],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget itemSolicitacao(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data();
    Timestamp timestamp = data['timestamp'];
    String dateTime = formatDateTime(timestamp.toDate());

    return Container(
      child: FlatButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Solicitacao(document: doc),
            ),
          );
          //async {
          //await _showDialog(data);
        },
        child: Column(
          children: [
            Row(
              children: <Widget>[
                AvatarTemplate(url: data['clientePhotoUrl']),
                Flexible(
                  flex: 2,
                  child: Container(
                    child: Column(
                      children: <Widget>[
                        Container(
                          child: Text(data['clienteName']),
                          alignment: Alignment.centerLeft,
                          margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 5.0),
                        ),
                        Container(
                          child: Text(dateTime),
                          alignment: Alignment.centerLeft,
                          margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 5.0),
                        ),
                        Container(
                          child: statusFrete(data['status']),
                          alignment: Alignment.centerLeft,
                          margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
                        ),
                      ],
                    ),
                    margin: EdgeInsets.only(left: 20.0),
                  ),
                ),
                _isLoading
                    ? CircularProgressIndicator(
                        strokeWidth: 1.0,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Consts.greenDark),
                      )
                    : (data['status'] == StatusFrete.EM_ANDAMENTO ||
                            data['status'] == StatusFrete.ESPERANDO_RESPOSTA)
                        ? IconButton(
                            icon: Icon(Icons.cancel_rounded),
                            onPressed: () async {
                              await _onSetStateFrete(
                                doc.reference,
                                newStatus: StatusFrete.REJEITADO,
                              );
                            },
                            color: Colors.red,
                          )
                        : IconButton(
                            icon: Icon(Icons.delete_rounded),
                            onPressed: () async {
                              await _onSetStateFrete(
                                doc.reference,
                              );
                            },
                            color: Colors.red,
                          ),
              ],
            ),
            bottomItem(data),
          ],
        ),
        padding: EdgeInsets.all(10.0),
      ),
      decoration: BoxDecoration(
        color: Consts.greyColor2,
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
      ),
      margin: EdgeInsets.all(5.0),
    );
  }

  Widget loadSolicitacoes() {
    return StreamBuilder(
      stream: solicitacoes
          .where('fretistaId', isEqualTo: model.getUserId)
          .where('visivelFretista', isEqualTo: true)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return SomethingWentWrong(snapshot.error.toString());
        }

        if (!snapshot.hasData) {
          return Loading();
        } else {
          if (snapshot.data.docs.isEmpty) {
            return noRequests();
          }
          return ListView.builder(
            padding: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 50.0),
            itemBuilder: (context, index) => itemSolicitacao(
              snapshot.data.docs[index],
            ),
            itemCount: snapshot.data.docs.length,
            controller: listScrollController,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: loadSolicitacoes(),
    );
  }
}
