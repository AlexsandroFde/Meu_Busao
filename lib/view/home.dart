import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mysql1/mysql1.dart';
import '../contants/constants.dart';
import '../model/mysql.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  MySQL db = MySQL();
  late MySqlConnection _connection;
  bool _conectado = false;
  Results? _passageiros;
  Results? _assentos;
  Results? _viagens;

  @override
  void initState() {
    super.initState();
    _connectToMySQL();
  }

  Future<void> _connectToMySQL() async{
    try{
      _connection = await db.getConnetion();
      await _varSQL();
      setState(() {
        _conectado = true;
      });
    }
    catch(e){
      setState(() {
        _conectado = false;
      });
    }
  }

  Future<void> _varSQL() async {
      _passageiros = await _connection.query('SELECT * FROM passageiro ORDER BY nome ASC;');
      _assentos = await _connection.query('''
        SELECT 
          a.idAssento, 
          COALESCE(p.idPassageiro, '') AS idPassageiro, 
          COALESCE(p.nome, 'Sem passageiro') AS nome, 
          t.sequencia, 
          v.idViagem
        FROM 
          viagem v
        JOIN 
          trecho t ON v.idViagem = t.idViagem
        LEFT JOIN 
          assento a ON t.idTrecho = a.idTrecho
        LEFT JOIN 
          passageiro p ON a.idPassageiro = p.idPassageiro
        ORDER BY 
          v.idViagem, t.sequencia, a.idAssento
      ''');
      _viagens = await _connection.query('''
        SELECT 
          v.idViagem, 
          v.data, 
          SUM(t.custo) AS valor,
          (SELECT COUNT(*) FROM assento a WHERE a.idTrecho = t.idTrecho AND a.idPassageiro IS NOT NULL) AS trecho1,
          (SELECT COUNT(*) FROM assento a WHERE a.idTrecho = t2.idTrecho AND a.idPassageiro IS NOT NULL) AS trecho2,
          (SELECT COUNT(*) FROM assento a WHERE a.idTrecho = t3.idTrecho AND a.idPassageiro IS NOT NULL) AS trecho3
        FROM 
          trecho t 
        JOIN 
          viagem v ON t.idViagem = v.idViagem 
        JOIN 
          trecho t2 ON t2.idViagem = v.idViagem AND t2.sequencia = 2
        JOIN 
          trecho t3 ON t3.idViagem = v.idViagem AND t3.sequencia = 3
        GROUP BY 
          v.idViagem, 
          v.data 
        ORDER BY 
          v.data DESC;
    ''');
  }

  Future<void> _cadastrarPassageiro() async {
    TextEditingController nomePassageiro = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String menssagem = 'Error\nConexão Não Estabelecida';
    String page = _conectado ? 'CADASTRAR' : 'CADASTRADO';

    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState){
            switch (page){
              case 'CADASTRAR': return Form(
                key: formKey,
                child: AlertDialog(
                  titlePadding: const EdgeInsets.all(0),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
                  title: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.only(topRight: Radius.circular(15), topLeft: Radius.circular(15))
                      ),
                      width: MediaQuery.of(context).size.width,
                      child: const Text('Cadastrar Passageiro', style: TextStyle(color: Colors.white))),
                  content: TextFormField(
                    keyboardType: TextInputType.name,
                    controller: nomePassageiro,
                    onChanged: (value) => setState((){}),
                    validator: (value){
                      if (value!.isEmpty || value.contains(';')){
                        return "Informe um Nome";
                      }
                      return null;
                    },
                    decoration: const InputDecoration(
                      border: UnderlineInputBorder(),
                      hintText: "Nome",
                      label: Text("Nome do Passageiro", style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  actions: [TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('CANCELAR'),
                  ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: nomePassageiro.text.isEmpty || nomePassageiro.text.contains(';') ? base.shade200 : null
                      ),
                      onPressed: () async {
                        if (formKey.currentState!.validate()){
                          setState(() {
                            page = '';
                          });
                          try{
                            await _connection.query('INSERT INTO passageiro (nome) VALUES ("${nomePassageiro.text}")');
                            await _connection.close();
                            await _connectToMySQL();
                            menssagem = 'Passageiro Cadastrado\nCom Sucesso';
                          }
                          catch(e){
                            menssagem = 'Error\nPassageiro Não Cadastrado';
                          }
                          setState(() {
                            page = 'CADASTRADO';
                          });
                        }
                      },
                      child: const Text('CADASTRAR', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
              case 'CADASTRADO': return Form(
                key: formKey,
                child: AlertDialog(
                  titlePadding: const EdgeInsets.all(0),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
                  title: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.only(topRight: Radius.circular(15), topLeft: Radius.circular(15))
                      ),
                      width: MediaQuery.of(context).size.width,
                      child: const Text('Cadastrar Passageiro', style: TextStyle(color: Colors.white),)),
                  content:
                  Text(menssagem),
                  actions:[TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('FECHAR'),
                  )]
                ),
              );
              default: return AlertDialog(
                titlePadding: const EdgeInsets.all(0),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
                title: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                        color: base,
                        borderRadius: BorderRadius.only(topRight: Radius.circular(15), topLeft: Radius.circular(15))
                    ),
                    width: MediaQuery.of(context).size.width,
                    child: const Text('Cadastrar Passageiro', style: TextStyle(color: Colors.white),)),
                content: const SizedBox(
                    height: 80,
                    child: Center(child: CircularProgressIndicator())),
                actions: [
                  TextButton(
                    onPressed: () {},
                    child: const Text('CANCELAR'),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('CADASTRAR', style: TextStyle(color: Colors.white)),
                  ),
                ],
              );
            }
          }
        );
      },
    ).then((value) => _conectado ? _connection.close() : null);
  }

  Future<void> _comprarAssento() async {
    String? passageiroSelecionado;
    String? viagemSelecionada;
    String page = _conectado ? 'COMPRAR' : 'COMPRADO';
    String menssagem = 'Error\nConexão Não Estabelecida';
    List<bool> trechosSelecionados = [true, false, false];
    List escolha = List.filled(45, false);
    final formKey = GlobalKey<FormState>();
    var id = -1;
    var trecho = 0;
    bool comprar = true;

    Results? assentos;
    final Results? passageiros = _passageiros;
    final Results? viagens = _viagens;
    final trechos = [
      'Fortaleza - Quixadá',
      'Quixadá - Iguatu',
      'Iguatu - Juazeiro'
    ];

    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            switch (page){
              case 'COMPRAR': return Form(
                key: formKey,
                child: AlertDialog(
                  titlePadding: const EdgeInsets.all(0),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
                  title: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.only(topRight: Radius.circular(15), topLeft: Radius.circular(15))
                    ),
                    width: MediaQuery.of(context).size.width,
                      child: const Text('Gerenciar Assentos', style: TextStyle(color: Colors.white),)),
                  content: SizedBox(
                    height: 345,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Escolha o passageiro:'),
                          DropdownButtonFormField(
                            hint: const Text('Passageiros'),
                            isExpanded: true,
                            menuMaxHeight: 300,
                            value: passageiroSelecionado,
                            onChanged: (value){
                              setState(() {
                                passageiroSelecionado = value!;
                              });
                            },
                            validator: (value){
                              if (value == null){
                                return "Escolha um passageiro";
                              }
                              return null;
                            },
                            items: passageiros!
                                .map((row) =>
                                DropdownMenuItem(
                                  value: '${row['idPassageiro']}',
                                  child: Text('[${row['idPassageiro']}] - ${row['nome']}'),
                                ))
                                .toList(),
                          ),
                          const SizedBox(height: 16),
                          const Text('Escolha a viagem:'),
                          DropdownButtonFormField(
                            hint: const Text('Viagens'),
                            isExpanded: true,
                            menuMaxHeight: 300,
                            value: viagemSelecionada,
                            onChanged: (String? value) {
                              setState(() {
                                viagemSelecionada = value!;
                              });
                            },
                            validator: (value){
                              if (value == null){
                                return "Escolha uma viagem";
                              }
                              return null;
                            },
                            items: viagens!
                                .map((row) =>
                                DropdownMenuItem(
                                  value: '${row['idViagem']}',
                                  child: Text('Viagem do dia ${DateFormat('dd/MM/yyyy').format(row['data'])}'),
                                ))
                                .toList(),
                          ),
                          const SizedBox(height: 16),
                          const Text('Escolha o trecho:'),
                          for (var i = 0; i < trechos.length; i++)
                            SizedBox(
                              height: 50,
                              width: 240,
                              child: CheckboxListTile(
                                checkboxShape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(5))),
                                title: Text(trechos[i]),
                                value: trechosSelecionados[i],
                                onChanged: (value) {
                                  setState(() {
                                    if(value == true) {
                                      if (trechosSelecionados.contains(true)) trechosSelecionados[trechosSelecionados.indexOf(true)] = false;
                                      trechosSelecionados[i] = value ?? false;
                                    }
                                  });
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('CANCELAR'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: passageiroSelecionado == null || viagemSelecionada == null ? base.shade200 : null
                      ),
                      onPressed: () async {
                        if (formKey.currentState!.validate()){
                          for (var i = 1; i <= trechosSelecionados.length; i++){
                            if (trechosSelecionados[i-1]){
                              try{
                                setState(() {
                                  page = '';
                                });
                                assentos = await _connection.query('SELECT * FROM assento WHERE idTrecho = (SELECT idTrecho FROM trecho WHERE idViagem = $viagemSelecionada AND sequencia = $i);');
                                trecho = assentos!.first['idTrecho'];
                                final result = await _connection.query('SELECT VerificaAssento($passageiroSelecionado, $trecho);');
                                comprar = result.first['VerificaAssento($passageiroSelecionado, $trecho)'] == 1 ? false : true;
                                setState(() {
                                  page = 'ESCOLHER';
                                });
                              }catch(e){
                                setState(() {
                                  page = 'COMPRADO';
                                });
                              }
                            }
                          }
                        }
                      },
                      child: const Text('AVANÇAR', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
              case 'ESCOLHER':
                List alfa = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L'];
                List num = [1, 2, 3, 4];
                return AlertDialog(
                  titlePadding: const EdgeInsets.all(0),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
                  title: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.only(topRight: Radius.circular(15), topLeft: Radius.circular(15))
                      ),
                      width: MediaQuery.of(context).size.width,
                      child: const Text('Gerenciar Assentos', style: TextStyle(color: Colors.white),)),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: 345,
                    child: GridView.count(
                      crossAxisCount: 4,
                      mainAxisSpacing: 8,
                      children: assentos!.map((row) {
                        return Padding(
                          padding: (((row['idAssento'] - 1) % 45) % 4) < 2
                              ?
                          const EdgeInsets.only(right: 8)
                              :
                          const EdgeInsets.only(left: 8),
                          child: ElevatedButton(
                            onPressed: () {
                              if (row['idPassageiro'] != null){
                                return;
                              }
                              var idAssento = ((row['idAssento'] - 1) % 45);
                                setState(() {
                                  if (escolha.contains(true)) escolha[escolha.indexOf(true)] = false;
                                  escolha[idAssento] = !escolha[idAssento];
                                  id = row['idAssento'];
                                });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: row['idPassageiro'] != null
                                  ?
                              row['idPassageiro'].toString() == passageiroSelecionado
                                    ?
                                secondBase.shade200
                                    :
                                base.shade200
                                  :
                              row['idAssento'] == id
                                    ?
                                secondBase
                                    :
                                null,
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('${alfa[((row['idAssento'] - 1) % 45) ~/ 4]}${num[((row['idAssento'] - 1) % 45) % 4]}',
                              style: TextStyle(
                                color: row['idPassageiro'].toString() == passageiroSelecionado || row['idAssento'] == id
                                    ?
                                row['idPassageiro'].toString() == passageiroSelecionado
                                      ?
                                  base.shade200
                                      :
                                  base
                                    :
                                Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          id = -1;
                          page = 'COMPRAR';
                        });
                      },
                      child: const Text('VOLTAR'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: id == -1 ? base.shade200 : null
                      ),
                      onPressed: id == -1 ? (){} : () async {
                        try{
                          setState(() {
                            page = '';
                          });
                          await _connection.query('CALL ComprarOuTrocarAssento($passageiroSelecionado, $trecho, $id)');
                          await _connection.close();
                          await _connectToMySQL();
                          if (comprar){
                            menssagem = 'Assento Comprado\nCom Sucesso';
                          }else{
                            menssagem = 'Assento Trocado\nCom Sucesso';
                          }
                        }
                        catch(e){
                          menssagem = 'Error\nAssento Não Comprado';
                        }
                        setState(() {
                          page = 'COMPRADO';
                        });
                      },
                      child: Text(comprar ? 'ALOCAR' : 'REALOCAR', style: const TextStyle(color: Colors.white)),
                    ),
                  ],
              );
              case 'COMPRADO': return AlertDialog(
                titlePadding: const EdgeInsets.all(0),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
                title: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                        color: base,
                        borderRadius: BorderRadius.only(topRight: Radius.circular(15), topLeft: Radius.circular(15))
                    ),
                    width: MediaQuery.of(context).size.width,
                    child: const Text('Gerenciar Assentos', style: TextStyle(color: Colors.white),)),
                content: Text(menssagem),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('FECHAR'),
                  ),
                ],
              );
              default: return AlertDialog(
                titlePadding: const EdgeInsets.all(0),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
                title: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                        color: base,
                        borderRadius: BorderRadius.only(topRight: Radius.circular(15), topLeft: Radius.circular(15))
                    ),
                    width: MediaQuery.of(context).size.width,
                    child: const Text('Gerenciar Assentos', style: TextStyle(color: Colors.white),)),
                  content: const SizedBox(
                      width: double.maxFinite,
                      height: 345,
                      child: Center(child: CircularProgressIndicator())),
                  actions: [
                    TextButton(
                      onPressed: () {},
                      child: const Text('VOLTAR'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: id == -1 ? base.shade200 : null
                      ),
                      onPressed: () {},
                      child: Text(comprar ? 'ALOCAR' : 'REALOCAR', style: const TextStyle(color: Colors.white)),
                    ),
                  ],
              );
            }
          }
        );
      },
    ).then((value) => _conectado ? _connection.close() : null);
  }

  Future<void> _adicionarViagem() async {
    DateTime hoje = DateTime.now();
    DateTime? dataEscolhida = hoje;
    String page = _conectado ? 'ADICIONAR' : 'ADICIONADO';
    String menssagem = 'Error\nConexão Não Estabelecida';
    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            switch (page){
              case 'ADICIONAR': return AlertDialog(
                titlePadding: const EdgeInsets.all(0),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
                title: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.only(topRight: Radius.circular(15), topLeft: Radius.circular(15))
                  ),
                  width: MediaQuery.of(context).size.width,
                  child: const Text('Adicionar Viagem', style: TextStyle(color: Colors.white),)),
                content: SizedBox(
                  height: 300,
                  width: double.maxFinite,
                  child: CalendarDatePicker(
                    initialDate: hoje,
                    firstDate: hoje,
                    lastDate: DateTime(2033),
                    onDateChanged: (date) {
                      setState(() {
                        dataEscolhida = date;
                      });
                    },
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('CANCELAR'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      try{
                        setState(() {
                          page = '';
                        });
                        final result = await _connection.query('SELECT ExisteViagem("${dataEscolhida.toString().substring(0, 10)}") AS existe;');
                        if (result.first['existe'] == 0){
                          await _connection.query('CALL CriarViagem("${dataEscolhida.toString().substring(0, 10)}")');
                          await _connection.close();
                          await _connectToMySQL();
                          menssagem = 'Viagem Criada\nCom Sucesso';
                        } else {
                          menssagem = 'Já Existe Uma Viagem\nMarcada Nesta Data';
                        }
                      }
                      catch(e){
                        menssagem = 'Error\nAssento Não Comprado';
                      }
                      setState(() {
                        page = 'ADICIONADO';
                      });
                    },
                    child: const Text('ADICIONAR', style: TextStyle(color: Colors.white)),
                  ),
                ],
              );
              case 'ADICIONADO' : return AlertDialog(
                titlePadding: const EdgeInsets.all(0),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
                title: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.only(topRight: Radius.circular(15), topLeft: Radius.circular(15))
                  ),
                  width: MediaQuery.of(context).size.width,
                  child: const Text('Adicionar Viagem', style: TextStyle(color: Colors.white),)),
                content: Text(menssagem),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('FECHAR'),
                  ),
                ],
              );
              default: return AlertDialog(
                titlePadding: const EdgeInsets.all(0),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
              title: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.only(topRight: Radius.circular(15), topLeft: Radius.circular(15))
                  ),
                  width: MediaQuery.of(context).size.width,
                  child: const Text('Adicionar Viagem', style: TextStyle(color: Colors.white),)),
                content: const SizedBox(
                  height: 300,
                  width: double.maxFinite,
                  child: Center(child: CircularProgressIndicator())),
                actions: [
                  TextButton(
                    onPressed: () {},
                    child: const Text('CANCELAR'),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('ADICIONAR', style: TextStyle(color: Colors.white)),
                  ),
                ],
              );
            }
          },
        );

      },
    ).then((value) => _conectado ? _connection.close() : null);
  }

  Future<void> _visualizarAssentos(int idViagem, DateTime data) async {
    var trechoSelecionado = 1;
    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState){
              List alfa = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L'];
              List num = [1, 2, 3, 4];
              return AlertDialog(
                titlePadding: const EdgeInsets.all(0),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
                title: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                        color: base,
                        borderRadius: BorderRadius.only(topRight: Radius.circular(15), topLeft: Radius.circular(15))
                    ),
                    width: MediaQuery.of(context).size.width,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(onPressed: trechoSelecionado == 1 ? null : () => setState(() {
                          trechoSelecionado = trechoSelecionado - 1;
                        }),
                            icon: const Icon(Icons.arrow_back), color: Colors.white),
                        Expanded(child: Text('${DateFormat('dd/MM/yyyy').format(data)}\nTrecho 0$trechoSelecionado', style: const TextStyle(color: Colors.white), textAlign: TextAlign.center)),
                        IconButton(onPressed: trechoSelecionado == 3 ? null : () => setState(() {
                          trechoSelecionado = trechoSelecionado + 1;
                        }),
                            icon: const Icon(Icons.arrow_forward), color: Colors.white)
                      ],
                    )),
                content: SizedBox(
                  width: double.maxFinite,
                  height: 400,
                  child: ListView(
                    children: [
                      DataTable(
                        columnSpacing: 0,
                        horizontalMargin: 0,
                        columns: const [
                          DataColumn(label: Text('Assento', textAlign: TextAlign.center), numeric: true),
                          DataColumn(label: Expanded(child: Text('Nome', textAlign: TextAlign.center))),
                          DataColumn(label: Text('Id', textAlign: TextAlign.center), numeric: true),
                        ],
                        rows: _assentos!
                            .where((row) => row['sequencia'] == trechoSelecionado && row['idViagem'] == idViagem)
                            .map((row) {
                          final assento = '${alfa[((row['idAssento'] - 1) % 45) ~/ 4]}${num[((row['idAssento'] - 1) % 45) % 4]}';
                          final color = row['idPassageiro'] == '' ? base : secondBase;
                          return DataRow(cells: [
                            DataCell(Center(child: Text(assento, textAlign: TextAlign.center, style: TextStyle(color: color)))),
                            DataCell(Center(child: Text('${row['nome']}', textAlign: TextAlign.center, style: TextStyle(color: color)))),
                            DataCell(Center(child: Text('${row['idPassageiro'] == '' ? '✗' : row['idPassageiro']}', textAlign: TextAlign.center, style: TextStyle(color: color)))),
                          ]);
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('FECHAR'),
                  ),
                ],
              );
            }
        );
      },
    ).then((value) => _conectado ? _connection.close() : null);
  }

  Future<void> _carregando() async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async{
            return false;
          },
          child: const AlertDialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            content: Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: Container(
          height: 45,
          width: 180,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/meu_busao.png'),
              fit: BoxFit.fill
            )
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: size.width / 6,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0),
                      ),
                    ),
                    onPressed: () async {
                      _carregando();
                      await _connectToMySQL().then((value) => Navigator.of(context).pop());
                      await _cadastrarPassageiro();
                    },
                    child: const Text(
                      'Cadastrar Passageiro',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: base,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: size.width / 6,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0),
                      ),
                    ),
                    onPressed: () async {
                      _carregando();
                      await _connectToMySQL().then((value) => Navigator.of(context).pop());
                      await _comprarAssento();
                    },
                    child: const Text(
                      'Gerenciar Assentos',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: base,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_conectado) Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 4),
              children: [
                ..._viagens!.map((row) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                    child: SizedBox(
                      height: 120,
                      child: MaterialButton(
                        padding: const EdgeInsets.all(0),
                        onPressed: () async {
                          _carregando();
                          await _connectToMySQL().then((value) => Navigator.of(context).pop());
                          await _visualizarAssentos(row['idViagem'], row['data']);
                        },
                        shape: const RoundedRectangleBorder(borderRadius:BorderRadius.only(topLeft: Radius.circular(5), bottomLeft: Radius.circular(200), topRight: Radius.elliptical(500, 90),bottomRight: Radius.circular(50))),
                        color: Colors.white,
                        textColor: Colors.grey.shade700,
                        elevation: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5), bottomRight: Radius.circular(50)),
                                    color: base,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        offset: Offset(2, 4),
                                        blurRadius: 3,
                                      )
                                    ]
                                  ),
                                  width: 2 * size.width / 3,
                                  child: Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Viagem do dia ${DateFormat('dd/MM/yyyy').format(row['data'])}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 19,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const Expanded(child: SizedBox()),
                                Container(
                                  alignment: AlignmentDirectional.center,
                                  height: 30,
                                  decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(5),topRight: Radius.circular(5), bottomRight: Radius.circular(15), topLeft: Radius.circular(15)),
                                    color: base,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black26,
                                        offset: Offset(2, 4),
                                        blurRadius: 3,
                                      )
                                    ]
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8, left: 8),
                                    child: Text('R\$${row['valor'].toStringAsFixed(2)}', textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 70,
                                  width: 100,
                                  decoration: const BoxDecoration(
                                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(5),bottomRight: Radius.circular(40)),
                                    image: DecorationImage(
                                        image: AssetImage('assets/busao.png'),
                                        fit: BoxFit.fitWidth
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black26,
                                          offset: Offset(2, 4),
                                          blurRadius: 3,
                                      )
                                    ]
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: SizedBox(
                                    width: 2 * size.width / 3 - 4,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Text('01.Fortaleza - Quixadá '),
                                            Expanded(
                                              child: Container(
                                                height: 1,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            Text(' [${row['trecho1']}/45]'),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Text('02.Quixadá - Iguatu '),
                                            Expanded(
                                              child: Container(
                                                height: 1,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            Text(' [${row['trecho2']}/45]'),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Text('03.Iguatu - Juazeiro '),
                                            Expanded(
                                              child: Container(
                                                height: 1,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                            Text(' [${row['trecho3']}/45]'),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
                const Divider(
                  color: Colors.black26,
                  thickness: 1,
                ),
                const SizedBox(
                  height: 90,
                  child: Text('Toque no "mais" para adicionar uma nova viagem', style: TextStyle(color: Colors.black45, fontSize: 11), textAlign: TextAlign.center),
                )
              ]
            ),
          ) else SizedBox(
            height: size.height/2,
            child: const Center(
                child: CircularProgressIndicator()),
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          _carregando();
          await _connectToMySQL().then((value) => Navigator.of(context).pop());
          await _adicionarViagem();
        },
        shape: const RoundedRectangleBorder(borderRadius: BorderRadiusDirectional.all(Radius.circular(20))),
        tooltip: 'Adicionar Viagem',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}