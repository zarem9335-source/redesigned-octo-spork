import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const MohsenPlcApp());
}

class MohsenPlcApp extends StatelessWidget {
  const MohsenPlcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MOHSEN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFECEFF1),
        primaryColor: const Color(0xFF00695C),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF00695C),
          secondary: Color(0xFFE65100),
          surface: Colors.white,
        ),
      ),
      home: const PlcWorkspaceScreen(),
    );
  }
}

enum BlockCategory { co, gf, sfTimer, sfCounter, sfAnalog, sfMisc }

enum EquipmentType { motor, lamp, pump, gate }

enum BlockType {
  input,
  analogInput,
  output,
  analogOutput,
  flag,
  high,
  low,
  andGate,
  andEdge,
  orGate,
  nandGate,
  norGate,
  xorGate,
  notGate,
  ton,
  tof,
  tonr,
  tp,
  pulse,
  stairway,
  weeklyTimer,
  yearlyTimer,
  ctud,
  hoursCounter,
  analogCmp,
  analogAmp,
  analogMath,
  piController,
  rs,
  impulse,
  shiftRegister,
  messageText,
}

extension BlockTypeInfo on BlockType {
  BlockCategory get category {
    switch (this) {
      case BlockType.input:
      case BlockType.analogInput:
      case BlockType.output:
      case BlockType.analogOutput:
      case BlockType.flag:
      case BlockType.high:
      case BlockType.low:
        return BlockCategory.co;
      case BlockType.andGate:
      case BlockType.andEdge:
      case BlockType.orGate:
      case BlockType.nandGate:
      case BlockType.norGate:
      case BlockType.xorGate:
      case BlockType.notGate:
        return BlockCategory.gf;
      case BlockType.ton:
      case BlockType.tof:
      case BlockType.tonr:
      case BlockType.tp:
      case BlockType.pulse:
      case BlockType.stairway:
      case BlockType.weeklyTimer:
      case BlockType.yearlyTimer:
        return BlockCategory.sfTimer;
      case BlockType.ctud:
      case BlockType.hoursCounter:
        return BlockCategory.sfCounter;
      case BlockType.analogCmp:
      case BlockType.analogAmp:
      case BlockType.analogMath:
      case BlockType.piController:
        return BlockCategory.sfAnalog;
      case BlockType.rs:
      case BlockType.impulse:
      case BlockType.shiftRegister:
      case BlockType.messageText:
        return BlockCategory.sfMisc;
    }
  }

  String get shortName {
    switch (this) {
      case BlockType.input:
        return 'I';
      case BlockType.analogInput:
        return 'AI';
      case BlockType.output:
        return 'Q';
      case BlockType.analogOutput:
        return 'AQ';
      case BlockType.flag:
        return 'M';
      case BlockType.high:
        return 'HI';
      case BlockType.low:
        return 'LO';
      case BlockType.andGate:
        return '&';
      case BlockType.andEdge:
        return '&↑';
      case BlockType.orGate:
        return '≥1';
      case BlockType.nandGate:
        return '&!';
      case BlockType.norGate:
        return '≥1!';
      case BlockType.xorGate:
        return '=1';
      case BlockType.notGate:
        return '1';
      case BlockType.ton:
        return 'T';
      case BlockType.tof:
        return 'T';
      case BlockType.tonr:
        return 'T!';
      case BlockType.tp:
        return 'TP';
      case BlockType.pulse:
        return '⊓⊔';
      case BlockType.stairway:
        return '⏚';
      case BlockType.weeklyTimer:
        return '📅';
      case BlockType.yearlyTimer:
        return '📆';
      case BlockType.ctud:
        return 'C±';
      case BlockType.hoursCounter:
        return '⏱';
      case BlockType.analogCmp:
        return 'A≥';
      case BlockType.analogAmp:
        return 'A×';
      case BlockType.analogMath:
        return 'A+';
      case BlockType.piController:
        return 'PI';
      case BlockType.rs:
        return 'RS';
      case BlockType.impulse:
        return '⏠';
      case BlockType.shiftRegister:
        return '>>';
      case BlockType.messageText:
        return 'TXT';
    }
  }

  String get title {
    switch (this) {
      case BlockType.input:
        return 'Input (I)';
      case BlockType.analogInput:
        return 'Analog In (AI)';
      case BlockType.output:
        return 'Output (Q)';
      case BlockType.analogOutput:
        return 'Analog Out (AQ)';
      case BlockType.flag:
        return 'Flag (M)';
      case BlockType.high:
        return 'High (1)';
      case BlockType.low:
        return 'Low (0)';
      case BlockType.andGate:
        return 'AND';
      case BlockType.andEdge:
        return 'AND (Edge)';
      case BlockType.orGate:
        return 'OR';
      case BlockType.nandGate:
        return 'NAND';
      case BlockType.norGate:
        return 'NOR';
      case BlockType.xorGate:
        return 'XOR';
      case BlockType.notGate:
        return 'NOT';
      case BlockType.ton:
        return 'On-Delay (TON)';
      case BlockType.tof:
        return 'Off-Delay (TOF)';
      case BlockType.tonr:
        return 'Retentive On';
      case BlockType.tp:
        return 'Wiping Relay';
      case BlockType.pulse:
        return 'Async Pulse';
      case BlockType.stairway:
        return 'Stairway Light';
      case BlockType.weeklyTimer:
        return 'Weekly Timer';
      case BlockType.yearlyTimer:
        return 'Yearly Timer';
      case BlockType.ctud:
        return 'Up/Dn Counter';
      case BlockType.hoursCounter:
        return 'Hours Counter';
      case BlockType.analogCmp:
        return 'Analog Thresh';
      case BlockType.analogAmp:
        return 'Analog Amp';
      case BlockType.analogMath:
        return 'Analog Math';
      case BlockType.piController:
        return 'PI Controller';
      case BlockType.rs:
        return 'Latching (RS)';
      case BlockType.impulse:
        return 'Impulse Relay';
      case BlockType.shiftRegister:
        return 'Shift Register';
      case BlockType.messageText:
        return 'Message Text';
    }
  }

  int get inputCount {
    switch (this) {
      case BlockType.input:
      case BlockType.analogInput:
      case BlockType.high:
      case BlockType.low:
      case BlockType.weeklyTimer:
      case BlockType.yearlyTimer:
        return 0;
      case BlockType.output:
      case BlockType.analogOutput:
      case BlockType.flag:
      case BlockType.notGate:
      case BlockType.ton:
      case BlockType.tof:
      case BlockType.tp:
      case BlockType.pulse:
      case BlockType.stairway:
      case BlockType.analogCmp:
      case BlockType.analogAmp:
      case BlockType.messageText:
        return 1;
      case BlockType.xorGate:
      case BlockType.tonr:
      case BlockType.rs:
      case BlockType.impulse:
      case BlockType.hoursCounter:
      case BlockType.analogMath:
      case BlockType.piController:
      case BlockType.shiftRegister:
        return 2;
      case BlockType.andGate:
      case BlockType.andEdge:
      case BlockType.orGate:
      case BlockType.nandGate:
      case BlockType.norGate:
      case BlockType.ctud:
        return 3;
    }
  }

  bool get hasOutput =>
      this != BlockType.output &&
      this != BlockType.analogOutput &&
      this != BlockType.messageText;

  List<String> get pinLabels {
    switch (this) {
      case BlockType.rs:
        return ['S', 'R'];
      case BlockType.impulse:
      case BlockType.tonr:
        return ['Trg', 'R'];
      case BlockType.ctud:
        return ['Cnt', 'Dir', 'R'];
      case BlockType.hoursCounter:
        return ['En', 'R'];
      case BlockType.shiftRegister:
        return ['In', 'Trg'];
      case BlockType.analogMath:
        return ['A1', 'A2'];
      case BlockType.piController:
        return ['PV', 'En'];
      case BlockType.ton:
      case BlockType.tof:
      case BlockType.tp:
      case BlockType.pulse:
      case BlockType.stairway:
        return ['Trg'];
      case BlockType.analogCmp:
      case BlockType.analogAmp:
      case BlockType.analogOutput:
        return ['Ax'];
      case BlockType.messageText:
        return ['En'];
      default:
        return List.generate(inputCount, (i) => '${i + 1}');
    }
  }

  Color get logoBodyColor => const Color(0xFFE5C158);
}

class PlcBlock {
  final String id;
  final String blockCode;
  final BlockType type;
  String label;
  double x;
  double y;
  bool value;
  double param;
  double param2;
  double elapsed;
  double analogVal;
  bool prevClk;
  bool isToggle;
  String messageText;
  double powerWatts;
  EquipmentType equipmentType;

  PlcBlock({
    required this.id,
    this.blockCode = 'B001',
    required this.type,
    required this.label,
    required this.x,
    required this.y,
    this.value = false,
    this.param = 3.0,
    this.param2 = 2.0,
    this.elapsed = 0.0,
    this.analogVal = 0.0,
    this.prevClk = false,
    this.isToggle = true,
    this.messageText = 'LOGO! SYSTEM READY',
    this.powerWatts = 100.0,
    this.equipmentType = EquipmentType.lamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': blockCode,
        'type': type.name,
        'label': label,
        'x': x,
        'y': y,
        'param': param,
        'param2': param2,
        'isToggle': isToggle,
        'messageText': messageText,
        'powerWatts': powerWatts,
        'equipmentType': equipmentType.name,
      };

  factory PlcBlock.fromJson(Map<String, dynamic> j) => PlcBlock(
        id: j['id'],
        blockCode: j['code'] ?? 'B001',
        type: BlockType.values.firstWhere((e) => e.name == j['type']),
        label: j['label'],
        x: (j['x'] as num).toDouble(),
        y: (j['y'] as num).toDouble(),
        param: (j['param'] as num?)?.toDouble() ?? 3.0,
        param2: (j['param2'] as num?)?.toDouble() ?? 2.0,
        isToggle: j['isToggle'] ?? true,
        messageText: j['messageText'] ?? 'LOGO! SYSTEM READY',
        powerWatts: (j['powerWatts'] as num?)?.toDouble() ?? 100.0,
        equipmentType: EquipmentType.values.firstWhere(
          (e) => e.name == (j['equipmentType'] ?? 'lamp'),
          orElse: () => EquipmentType.lamp,
        ),
      );
}

class PlcWire {
  final String id;
  final String fromBlockId;
  final String toBlockId;
  final int toPinIndex;

  PlcWire({
    required this.id,
    required this.fromBlockId,
    required this.toBlockId,
    required this.toPinIndex,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'from': fromBlockId,
        'to': toBlockId,
        'pin': toPinIndex,
      };

  factory PlcWire.fromJson(Map<String, dynamic> j) => PlcWire(
        id: j['id'],
        fromBlockId: j['from'],
        toBlockId: j['to'],
        toPinIndex: j['pin'],
      );
}

abstract class LadNode {
  bool isActive(Map<String, PlcBlock> map);
}

class LadContact extends LadNode {
  final String blockId;
  final String label;
  final bool inverted;
  LadContact(this.blockId, this.label, {this.inverted = false});

  @override
  bool isActive(Map<String, PlcBlock> map) {
    final val = map[blockId]?.value ?? false;
    return inverted ? !val : val;
  }
}

class LadSeries extends LadNode {
  final List<LadNode> items;
  LadSeries(this.items);
  @override
  bool isActive(Map<String, PlcBlock> map) =>
      items.isNotEmpty && items.every((e) => e.isActive(map));
}

class LadParallel extends LadNode {
  final List<LadNode> branches;
  LadParallel(this.branches);
  @override
  bool isActive(Map<String, PlcBlock> map) =>
      branches.any((e) => e.isActive(map));
}

class LadRung {
  final String coilLabel;
  final PlcBlock targetBlock;
  final LadNode? condition;
  LadRung({
    required this.coilLabel,
    required this.targetBlock,
    required this.condition,
  });
}

class PlcWorkspaceScreen extends StatefulWidget {
  const PlcWorkspaceScreen({super.key});

  @override
  State<PlcWorkspaceScreen> createState() => _PlcWorkspaceScreenState();
}

class _PlcWorkspaceScreenState extends State<PlcWorkspaceScreen>
    with SingleTickerProviderStateMixin {
  static const double blockWidth = 84.0;
  static const double blockHeight = 64.0;

  final GlobalKey _canvasRepaintKey = GlobalKey();

  final List<List<PlcBlock>> pagesBlocks = [[]];
  final List<List<PlcWire>> pagesWires = [[]];
  final List<String> pageNames = ['صفحه ۱'];
  int currentPage = 0;

  List<PlcBlock> get blocks => pagesBlocks[currentPage];
  set blocks(List<PlcBlock> v) => pagesBlocks[currentPage] = v;

  List<PlcWire> get wires => pagesWires[currentPage];
  set wires(List<PlcWire> v) => pagesWires[currentPage] = v;
  final List<Map<String, bool>> scopeHistory = [];
  final Map<String, double> tankLevels = {};
  final Map<String, double> gatePositions = {};

  bool isSimulating = false;
  bool isPowerOutage = false;
  bool showTreeSidebar = true;
  bool isWireTool = false;
  bool isCanvasLocked = false;
  Offset? dragWireStart;
  Offset? dragWireCurrent;
  String? dragFromBlockId;
  String hostUrl = 'https://mmm.morningg.ir/circuit_api.php';
  String aiApiUrl = 'https://api.openai.com/v1/chat/completions';
  String aiApiKey = '';
  String aiModel = 'gpt-4o-mini';
  bool vibrateOnOutput = true;
  final Map<String, bool> _prevOutValues = {};
  int viewMode = 0; // 0: FBD, 1: LAD, 2: SCOPE, 3: PLANT (کارگاهی)
  double simHour = 19.0;
  Timer? _simTimer;
  String? selectedOutputBlockId;
  int _idCounter = 1;
  late AnimationController _motorAnim;

  @override
  void initState() {
    super.initState();
    _motorAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _loadTemplate('p1_multi_switch');
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    _motorAnim.dispose();
    super.dispose();
  }

  String _nextId(String prefix) => '${prefix}_${_idCounter++}';

  void _addNewBlankPage() {
    if (isSimulating) _toggleSimulation();
    setState(() {
      pagesBlocks.add([]);
      pagesWires.add([]);
      pageNames.add('صفحه ${pagesBlocks.length}');
      currentPage = pagesBlocks.length - 1;
      selectedOutputBlockId = null;
    });
  }

  void _switchPage(int idx) {
    if (idx == currentPage) return;
    if (isSimulating) _toggleSimulation();
    setState(() {
      currentPage = idx;
      selectedOutputBlockId = null;
    });
  }

  void _closePage(int idx) {
    if (pagesBlocks.length <= 1) return;
    if (isSimulating) _toggleSimulation();
    setState(() {
      pagesBlocks.removeAt(idx);
      pagesWires.removeAt(idx);
      pageNames.removeAt(idx);
      if (currentPage >= pagesBlocks.length) {
        currentPage = pagesBlocks.length - 1;
      }
      selectedOutputBlockId = null;
    });
  }

  void _toggleSimulation() {
    setState(() {
      isSimulating = !isSimulating;
      isPowerOutage = false;
      selectedOutputBlockId = null;
      if (isSimulating) {
        scopeHistory.clear();
        for (final b in blocks) {
          if (b.type != BlockType.input && b.type != BlockType.analogInput) {
            b.value = (b.type == BlockType.high);
            b.elapsed = 0.0;
            b.prevClk = false;
          }
        }
        _simTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
          _evaluateCycle(0.1);
        });
      } else {
        _simTimer?.cancel();
        _simTimer = null;
        for (final b in blocks) {
          b.value = false;
          b.elapsed = 0.0;
          b.prevClk = false;
        }
      }
    });
  }

  void _togglePowerOutage() {
    if (!isSimulating) return;
    setState(() {
      isPowerOutage = !isPowerOutage;
      if (isPowerOutage) {
        // Non-retentive blocks reset on power failure; TONR, CTUD, OT keep elapsed!
        for (final b in blocks) {
          if (b.type != BlockType.tonr &&
              b.type != BlockType.ctud &&
              b.type != BlockType.hoursCounter) {
            b.value = false;
            if (b.type != BlockType.analogInput) b.elapsed = 0.0;
          } else {
            b.value = false;
          }
        }
      }
    });
  }

  void _evaluateCycle(double dt) {
    if (isPowerOutage) return;
    final Map<String, PlcBlock> blockMap = {for (var b in blocks) b.id: b};

    bool getPinVal(String blockId, int pinIndex) {
      final w = wires.where(
        (wire) => wire.toBlockId == blockId && wire.toPinIndex == pinIndex,
      );
      if (w.isEmpty) return false;
      return blockMap[w.first.fromBlockId]?.value ?? false;
    }

    double getAnalogPinVal(String blockId, int pinIndex) {
      final w = wires.where(
        (wire) => wire.toBlockId == blockId && wire.toPinIndex == pinIndex,
      );
      if (w.isEmpty) return 0.0;
      return blockMap[w.first.fromBlockId]?.analogVal ?? 0.0;
    }

    List<bool> getConnectedInputs(PlcBlock b) {
      final list = <bool>[];
      for (int i = 0; i < b.type.inputCount; i++) {
        if (wires.any((w) => w.toBlockId == b.id && w.toPinIndex == i)) {
          list.add(getPinVal(b.id, i));
        }
      }
      return list;
    }

    setState(() {
      for (int pass = 0; pass < 2; pass++) {
        for (final b in blocks) {
          switch (b.type) {
            case BlockType.input:
              break;
            case BlockType.analogInput:
              b.value = b.analogVal > 0.0;
              break;
            case BlockType.high:
              b.value = true;
              break;
            case BlockType.low:
              b.value = false;
              break;
            case BlockType.weeklyTimer:
            case BlockType.yearlyTimer:
              if (b.param <= b.param2) {
                b.value = simHour >= b.param && simHour < b.param2;
              } else {
                b.value = simHour >= b.param || simHour < b.param2;
              }
              break;
            case BlockType.output:
            case BlockType.flag:
            case BlockType.messageText:
              b.value = getPinVal(b.id, 0);
              break;
            case BlockType.analogOutput:
              b.analogVal = getAnalogPinVal(b.id, 0);
              b.value = b.analogVal > 0.0;
              break;
            case BlockType.andGate:
              final ins = getConnectedInputs(b);
              b.value = ins.isNotEmpty && ins.every((v) => v);
              break;
            case BlockType.andEdge:
              if (pass == 0) {
                final ins = getConnectedInputs(b);
                final cur = ins.isNotEmpty && ins.every((v) => v);
                b.value = cur && !b.prevClk;
                b.prevClk = cur;
              }
              break;
            case BlockType.orGate:
              b.value = getConnectedInputs(b).any((v) => v);
              break;
            case BlockType.nandGate:
              final ins = getConnectedInputs(b);
              b.value = !(ins.isNotEmpty && ins.every((v) => v));
              break;
            case BlockType.norGate:
              b.value = !getConnectedInputs(b).any((v) => v);
              break;
            case BlockType.xorGate:
              b.value = getPinVal(b.id, 0) != getPinVal(b.id, 1);
              break;
            case BlockType.notGate:
              b.value = !getPinVal(b.id, 0);
              break;
            case BlockType.rs:
              final s = getPinVal(b.id, 0);
              final r = getPinVal(b.id, 1);
              if (r) {
                b.value = false;
              } else if (s) {
                b.value = true;
              }
              break;
            case BlockType.impulse:
              if (pass == 0) {
                final trg = getPinVal(b.id, 0);
                final rst = getPinVal(b.id, 1);
                if (rst) {
                  b.value = false;
                } else if (trg && !b.prevClk) {
                  b.value = !b.value;
                }
                b.prevClk = trg;
              }
              break;
            case BlockType.shiftRegister:
              if (pass == 0) {
                final dataIn = getPinVal(b.id, 0);
                final trg = getPinVal(b.id, 1);
                if (trg && !b.prevClk) b.value = dataIn;
                b.prevClk = trg;
              }
              break;
            case BlockType.ton:
              if (pass == 0) {
                final trg = getPinVal(b.id, 0);
                if (trg) {
                  if (b.elapsed < b.param) b.elapsed += dt;
                  b.value = b.elapsed >= b.param;
                } else {
                  b.elapsed = 0.0;
                  b.value = false;
                }
              }
              break;
            case BlockType.tonr:
              if (pass == 0) {
                final trg = getPinVal(b.id, 0);
                final rst = getPinVal(b.id, 1);
                if (rst) {
                  b.elapsed = 0.0;
                  b.value = false;
                } else if (trg) {
                  if (b.elapsed < b.param) b.elapsed += dt;
                  b.value = b.elapsed >= b.param;
                }
              }
              break;
            case BlockType.tof:
            case BlockType.stairway:
              if (pass == 0) {
                final trg = getPinVal(b.id, 0);
                if (trg) {
                  b.value = true;
                  b.elapsed = 0.0;
                } else if (b.value) {
                  b.elapsed += dt;
                  if (b.elapsed >= b.param) {
                    b.value = false;
                    b.elapsed = b.param;
                  }
                }
              }
              break;
            case BlockType.tp:
              if (pass == 0) {
                final trg = getPinVal(b.id, 0);
                if (trg && !b.prevClk) {
                  b.value = true;
                  b.elapsed = 0.0;
                }
                if (b.value) {
                  b.elapsed += dt;
                  if (b.elapsed >= b.param) {
                    b.value = false;
                    b.elapsed = 0.0;
                  }
                }
                b.prevClk = trg;
              }
              break;
            case BlockType.pulse:
              if (pass == 0) {
                final trg = getPinVal(b.id, 0);
                if (trg) {
                  b.elapsed += dt;
                  if (b.elapsed >= b.param) {
                    b.elapsed = 0.0;
                    b.value = !b.value;
                  }
                } else {
                  b.elapsed = 0.0;
                  b.value = false;
                }
              }
              break;
            case BlockType.ctud:
              if (pass == 0) {
                final cntUp = getPinVal(b.id, 0);
                final cntDn = getPinVal(b.id, 1);
                final rst = getPinVal(b.id, 2);
                if (rst) {
                  b.elapsed = 0.0;
                  b.value = false;
                } else {
                  if (cntUp && !b.prevClk) b.elapsed += 1.0;
                  if (cntDn && b.elapsed > 0) b.elapsed = math.max(0, b.elapsed - 0.5);
                }
                b.prevClk = cntUp;
                b.value = b.elapsed >= b.param;
              }
              break;
            case BlockType.hoursCounter:
              if (pass == 0) {
                final en = getPinVal(b.id, 0);
                final rst = getPinVal(b.id, 1);
                if (rst) {
                  b.elapsed = 0.0;
                  b.value = false;
                } else if (en) {
                  b.elapsed += dt;
                  b.value = b.elapsed >= b.param;
                }
              }
              break;
            case BlockType.analogCmp:
              b.analogVal = getAnalogPinVal(b.id, 0);
              if (b.analogVal >= b.param) {
                b.value = true;
              } else if (b.analogVal <= b.param2) {
                b.value = false;
              }
              break;
            case BlockType.analogAmp:
              b.analogVal = (getAnalogPinVal(b.id, 0) * b.param).clamp(0.0, 100.0);
              b.value = b.analogVal > 0;
              break;
            case BlockType.analogMath:
              b.analogVal = getAnalogPinVal(b.id, 0) + getAnalogPinVal(b.id, 1);
              b.value = b.analogVal >= b.param;
              break;
            case BlockType.piController:
              final pv = getAnalogPinVal(b.id, 0);
              final en = getPinVal(b.id, 1);
              if (en) {
                final err = b.param - pv;
                b.analogVal = (err * 1.5).clamp(0.0, 10.0);
                b.value = b.analogVal > 0.5;
              } else {
                b.analogVal = 0.0;
                b.value = false;
              }
              break;
          }
        }
      }

      // Update plant equipment simulation levels
      for (final b in blocks) {
        if (b.type == BlockType.output) {
          if (b.equipmentType == EquipmentType.pump) {
            final cur = tankLevels[b.id] ?? 0.3;
            tankLevels[b.id] = b.value
                ? math.min(1.0, cur + 0.03)
                : math.max(0.1, cur - 0.01);
          } else if (b.equipmentType == EquipmentType.gate) {
            final cur = gatePositions[b.id] ?? 0.0;
            gatePositions[b.id] = b.value
                ? math.min(1.0, cur + 0.05)
                : math.max(0.0, cur - 0.05);
          }
        }
      }

      if (vibrateOnOutput) {
        for (final b in blocks.where((e) => e.type == BlockType.output)) {
          final was = _prevOutValues[b.id] ?? false;
          if (b.value && !was) {
            HapticFeedback.heavyImpact();
          }
          _prevOutValues[b.id] = b.value;
        }
      }
      final snap = <String, bool>{};
      for (final b in blocks) {
        if (b.type == BlockType.input || b.type == BlockType.output) {
          snap[b.label] = b.value;
        }
      }
      scopeHistory.add(snap);
      if (scopeHistory.length > 60) scopeHistory.removeAt(0);
    });
  }

  String _identifyDrawnCircuit() {
    if (blocks.isEmpty) return 'صفحه خالی است — هیچ مداری رسم نشده است.';

    final types = blocks.map((b) => b.type).toSet();
    final outCount = blocks.where((b) => b.type == BlockType.output).length;
    final rsCount = blocks.where((b) => b.type == BlockType.rs).length;
    final notCount = blocks.where((b) => b.type == BlockType.notGate).length;
    final stwCount = blocks.where((b) => b.type == BlockType.stairway).length;

    if (stwCount >= 3 && outCount >= 4) {
      return 'مدار شستی چندکاره روشنایی (شکل ۲۸ - کار عملی ۶ کتاب)';
    }
    if (types.contains(BlockType.rs) &&
        types.contains(BlockType.ton) &&
        types.contains(BlockType.notGate) &&
        types.contains(BlockType.andGate) &&
        outCount >= 3) {
      return 'مدار راه‌اندازی موتور سه‌فاز ستاره-مثلث خودکار (Star-Delta)';
    }
    if (rsCount >= 2 && notCount >= 2 && outCount >= 2) {
      return 'مدار موتور چپ‌گرد و راست‌گرد / درب اتوماتیک (با اینترلاک حفاظتی)';
    }
    if (rsCount >= 2 && notCount == 0 && outCount >= 2) {
      return 'مدار چپ‌گرد و راست‌گرد (هشدار: بدون اینترلاک!)';
    }
    if (types.contains(BlockType.piController)) {
      return 'مدار کنترل حلقه بسته صنعتی (PI Controller)';
    }
    if (types.contains(BlockType.shiftRegister)) {
      return 'مدار خط تولید / شیفت رجیستر ترتیبی';
    }
    if (types.contains(BlockType.xorGate) && outCount == 1) {
      return 'مدار روشنایی تبدیل (کلید تبدیل با گیت XOR)';
    }
    if (types.contains(BlockType.stairway) || types.contains(BlockType.tof)) {
      return 'مدار روشنایی راه‌پله / فن تاخیردار (TOF/STW)';
    }
    if (types.contains(BlockType.impulse)) {
      return 'مدار روشنایی با رله پله‌ای (Impulse Relay)';
    }
    if (types.contains(BlockType.weeklyTimer) || types.contains(BlockType.yearlyTimer)) {
      return 'مدار روشنایی هوشمند / ویترین با تایمر هفتگی';
    }
    if (types.contains(BlockType.notGate) && types.contains(BlockType.rs) && outCount == 1) {
      return 'مدار کنترل اتوماتیک پمپ و مخزن آب (سنسور کف و سقف)';
    }
    if (types.contains(BlockType.rs) && outCount == 1) {
      return 'مدار استارت/استپ دائم موتور (Self-Hold با RS)';
    }
    if (types.contains(BlockType.analogInput) && types.contains(BlockType.analogCmp)) {
      return 'مدار کنترل دما / سطح آنالوگ با مقایسه‌گر';
    }
    if (types.contains(BlockType.ctud)) {
      return 'مدار شمارنده قطعات صنعتی (CTUD)';
    }
    if (types.contains(BlockType.tonr)) {
      return 'مدار تایمر ماندگار مقاوم در برابر قطع برق (TONR)';
    }
    if (types.contains(BlockType.pulse)) {
      return 'مدار چشمک‌زن / آژیر هشدار متناوب (Async Pulse)';
    }
    if (types.contains(BlockType.ton) && outCount >= 2) {
      return 'مدار راه‌اندازی ترتیبی دو موتور با تاخیر (Sequential Start)';
    }

    final gateNames = blocks
        .where((b) => b.type.category == BlockCategory.gf)
        .map((b) => b.type.title)
        .toSet()
        .join('، ');
    return 'مدار منطقی سفارشی (${blocks.length} بلوک${gateNames.isNotEmpty ? " شامل $gateNames" : ""})';
  }

  void _drawCircuitByName(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return;

    if (q.contains('ستاره') || q.contains('مثلث') || q.contains('star')) {
      _loadTemplate('p2_stardelta');
    } else if (q.contains('چندکاره') || q.contains('28') || q.contains('۲۸') || q.contains('همکف')) {
      _loadTemplate('p1_multi_switch');
    } else if (q.contains('پمپ') || q.contains('مخزن') || q.contains('آب') || q.contains('pump')) {
      _loadTemplate('p3_pump');
    } else if (q.contains('چپ') || q.contains('راست') || q.contains('دوجهت') || q.contains('rev')) {
      _loadReversingWithInterlock();
    } else if (q.contains('پارکینگ') || q.contains('درب') || q.contains('کرکره') || q.contains('gate')) {
      _loadParkingGateCircuit();
    } else if (q.contains('ترتیب') || q.contains('نوبتی') || q.contains('دو موتور') || q.contains('sequential')) {
      _loadSequentialMotorsCircuit();
    } else if (q.contains('ترافیک') || q.contains('راهنمایی') || q.contains('traffic')) {
      _loadTrafficLightCircuit();
    } else if (q.contains('آژیر') || q.contains('دزدگیر') || q.contains('اضطراری') || q.contains('alarm')) {
      _loadAlarmCircuit();
    } else if (q.contains('هفتگی') || q.contains('هوشمند') || q.contains('ویترین') || q.contains('معابر')) {
      _loadWeeklyLightingCircuit();
    } else if (q.contains('ماندگار') || q.contains('قطع برق') || q.contains('خشک') || q.contains('tonr')) {
      _loadTemplate('p5_retentive');
    } else if (q.contains('تبدیل') || q.contains('xor')) {
      _loadBasicCircuit(BlockType.xorGate, 2);
    } else if (q.contains('راه‌پله') || q.contains('راه پله') || q.contains('پله')) {
      _loadBasicCircuit(BlockType.stairway, 1);
    } else if (q.contains('پله‌ای') || q.contains('impulse')) {
      _loadBasicCircuit(BlockType.impulse, 2);
    } else if (q.contains('استارت') || q.contains('دائم') || q.contains('rs')) {
      _loadBasicCircuit(BlockType.rs, 2);
    } else if (q.contains('شمارنده') || q.contains('قطعه') || q.contains('نقاله') || q.contains('count')) {
      _loadBasicCircuit(BlockType.ctud, 1);
    } else if (q.contains('چشمک') || q.contains('پالس') || q.contains('فلاشر') || q.contains('blink')) {
      _loadBasicCircuit(BlockType.pulse, 1);
    } else if (q.contains('دما') || q.contains('کوره') || q.contains('آنالوگ') || q.contains('گلخانه')) {
      _loadBasicCircuit(BlockType.analogCmp, 1);
    } else if (q.contains('pi') || q.contains('کنترلر')) {
      _loadBasicCircuit(BlockType.piController, 2);
    } else if (q.contains('شیفت') || q.contains('shift')) {
      _loadBasicCircuit(BlockType.shiftRegister, 2);
    } else if (q.contains('nand')) {
      _loadBasicCircuit(BlockType.nandGate, 2);
    } else if (q.contains('nor')) {
      _loadBasicCircuit(BlockType.norGate, 2);
    } else if (q.contains('and') || q.contains('سری')) {
      _loadBasicCircuit(BlockType.andGate, 2);
    } else if (q.contains('or') || q.contains('موازی')) {
      _loadBasicCircuit(BlockType.orGate, 2);
    } else if (q.contains('not') || q.contains('نقیض')) {
      _loadBasicCircuit(BlockType.notGate, 1);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('نام مدار پیدا نشد! از لیست آماده انتخاب کن یا اسم دقیق‌تری بنویس.'),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('مدار "$query" رسم شد!')),
    );
  }

  void _loadReversingWithInterlock() {
    if (isSimulating) _toggleSimulation();
    setState(() {
      blocks = [
        PlcBlock(id: 'i1', blockCode: 'I1', type: BlockType.input, label: 'راست', x: 20, y: 40, isToggle: false),
        PlcBlock(id: 'i2', blockCode: 'I2', type: BlockType.input, label: 'چپ', x: 20, y: 160, isToggle: false),
        PlcBlock(id: 'i3', blockCode: 'I3', type: BlockType.input, label: 'Stop', x: 20, y: 270, isToggle: false),
        PlcBlock(id: 'n1', blockCode: 'B001', type: BlockType.notGate, label: 'NOT_L', x: 150, y: 95),
        PlcBlock(id: 'n2', blockCode: 'B002', type: BlockType.notGate, label: 'NOT_R', x: 150, y: 200),
        PlcBlock(id: 'a1', blockCode: 'B003', type: BlockType.andGate, label: 'AND_R', x: 270, y: 40),
        PlcBlock(id: 'a2', blockCode: 'B004', type: BlockType.andGate, label: 'AND_L', x: 270, y: 170),
        PlcBlock(id: 'r1', blockCode: 'B005', type: BlockType.rs, label: 'RS_R', x: 390, y: 40),
        PlcBlock(id: 'r2', blockCode: 'B006', type: BlockType.rs, label: 'RS_L', x: 390, y: 170),
        PlcBlock(id: 'q1', blockCode: 'Q1', type: BlockType.output, label: 'راست‌گرد', x: 520, y: 40, powerWatts: 1500, equipmentType: EquipmentType.motor),
        PlcBlock(id: 'q2', blockCode: 'Q2', type: BlockType.output, label: 'چپ‌گرد', x: 520, y: 170, powerWatts: 1500, equipmentType: EquipmentType.motor),
      ];
      wires = [
        PlcWire(id: 'w1', fromBlockId: 'i1', toBlockId: 'a1', toPinIndex: 0),
        PlcWire(id: 'w2', fromBlockId: 'n1', toBlockId: 'a1', toPinIndex: 1),
        PlcWire(id: 'w3', fromBlockId: 'a1', toBlockId: 'r1', toPinIndex: 0),
        PlcWire(id: 'w4', fromBlockId: 'i3', toBlockId: 'r1', toPinIndex: 1),
        PlcWire(id: 'w5', fromBlockId: 'r1', toBlockId: 'q1', toPinIndex: 0),
        PlcWire(id: 'w6', fromBlockId: 'i2', toBlockId: 'a2', toPinIndex: 0),
        PlcWire(id: 'w7', fromBlockId: 'n2', toBlockId: 'a2', toPinIndex: 1),
        PlcWire(id: 'w8', fromBlockId: 'a2', toBlockId: 'r2', toPinIndex: 0),
        PlcWire(id: 'w9', fromBlockId: 'i3', toBlockId: 'r2', toPinIndex: 1),
        PlcWire(id: 'w10', fromBlockId: 'r2', toBlockId: 'q2', toPinIndex: 0),
        PlcWire(id: 'w11', fromBlockId: 'r2', toBlockId: 'n1', toPinIndex: 0),
        PlcWire(id: 'w12', fromBlockId: 'r1', toBlockId: 'n2', toPinIndex: 0),
      ];
    });
  }

  void _loadParkingGateCircuit() {
    if (isSimulating) _toggleSimulation();
    setState(() {
      blocks = [
        PlcBlock(id: 'i1', blockCode: 'I1', type: BlockType.input, label: 'باز کردن', x: 30, y: 40, isToggle: false),
        PlcBlock(id: 'i2', blockCode: 'I2', type: BlockType.input, label: 'لیمیت باز', x: 30, y: 140, isToggle: false),
        PlcBlock(id: 'i3', blockCode: 'I3', type: BlockType.input, label: 'بستن', x: 30, y: 240, isToggle: false),
        PlcBlock(id: 'i4', blockCode: 'I4', type: BlockType.input, label: 'لیمیت بسته', x: 30, y: 340, isToggle: false),
        PlcBlock(id: 'r1', blockCode: 'B001', type: BlockType.rs, label: 'RS_Open', x: 220, y: 60),
        PlcBlock(id: 'r2', blockCode: 'B002', type: BlockType.rs, label: 'RS_Close', x: 220, y: 260),
        PlcBlock(id: 'q1', blockCode: 'Q1', type: BlockType.output, label: 'موتور باز', x: 400, y: 60, powerWatts: 500, equipmentType: EquipmentType.gate),
        PlcBlock(id: 'q2', blockCode: 'Q2', type: BlockType.output, label: 'موتور بسته', x: 400, y: 260, powerWatts: 500, equipmentType: EquipmentType.gate),
      ];
      wires = [
        PlcWire(id: 'w1', fromBlockId: 'i1', toBlockId: 'r1', toPinIndex: 0),
        PlcWire(id: 'w2', fromBlockId: 'i2', toBlockId: 'r1', toPinIndex: 1),
        PlcWire(id: 'w3', fromBlockId: 'r1', toBlockId: 'q1', toPinIndex: 0),
        PlcWire(id: 'w4', fromBlockId: 'i3', toBlockId: 'r2', toPinIndex: 0),
        PlcWire(id: 'w5', fromBlockId: 'i4', toBlockId: 'r2', toPinIndex: 1),
        PlcWire(id: 'w6', fromBlockId: 'r2', toBlockId: 'q2', toPinIndex: 0),
      ];
    });
  }

  void _loadSequentialMotorsCircuit() {
    if (isSimulating) _toggleSimulation();
    setState(() {
      blocks = [
        PlcBlock(id: 'i1', blockCode: 'I1', type: BlockType.input, label: 'Start', x: 30, y: 50, isToggle: false),
        PlcBlock(id: 'i2', blockCode: 'I2', type: BlockType.input, label: 'Stop', x: 30, y: 150, isToggle: false),
        PlcBlock(id: 'r1', blockCode: 'B001', type: BlockType.rs, label: 'RS', x: 170, y: 80),
        PlcBlock(id: 't1', blockCode: 'B002', type: BlockType.ton, label: 'TON (5s)', x: 290, y: 180, param: 5.0),
        PlcBlock(id: 'q1', blockCode: 'Q1', type: BlockType.output, label: 'موتور ۱', x: 440, y: 80, powerWatts: 1500, equipmentType: EquipmentType.motor),
        PlcBlock(id: 'q2', blockCode: 'Q2', type: BlockType.output, label: 'موتور ۲', x: 440, y: 180, powerWatts: 1500, equipmentType: EquipmentType.motor),
      ];
      wires = [
        PlcWire(id: 'w1', fromBlockId: 'i1', toBlockId: 'r1', toPinIndex: 0),
        PlcWire(id: 'w2', fromBlockId: 'i2', toBlockId: 'r1', toPinIndex: 1),
        PlcWire(id: 'w3', fromBlockId: 'r1', toBlockId: 'q1', toPinIndex: 0),
        PlcWire(id: 'w4', fromBlockId: 'r1', toBlockId: 't1', toPinIndex: 0),
        PlcWire(id: 'w5', fromBlockId: 't1', toBlockId: 'q2', toPinIndex: 0),
      ];
    });
  }

  void _loadTrafficLightCircuit() {
    if (isSimulating) _toggleSimulation();
    setState(() {
      blocks = [
        PlcBlock(id: 'i1', blockCode: 'I1', type: BlockType.input, label: 'برق اصلی', x: 30, y: 100),
        PlcBlock(id: 't1', blockCode: 'B001', type: BlockType.ton, label: 'T_Yellow', x: 170, y: 160, param: 4.0),
        PlcBlock(id: 't2', blockCode: 'B002', type: BlockType.ton, label: 'T_Green', x: 310, y: 240, param: 4.0),
        PlcBlock(id: 'n1', blockCode: 'B003', type: BlockType.notGate, label: 'NOT', x: 310, y: 60),
        PlcBlock(id: 'q1', blockCode: 'Q1', type: BlockType.output, label: 'چراغ قرمز', x: 470, y: 60, powerWatts: 60, equipmentType: EquipmentType.lamp),
        PlcBlock(id: 'q2', blockCode: 'Q2', type: BlockType.output, label: 'چراغ زرد', x: 470, y: 160, powerWatts: 60, equipmentType: EquipmentType.lamp),
        PlcBlock(id: 'q3', blockCode: 'Q3', type: BlockType.output, label: 'چراغ سبز', x: 470, y: 240, powerWatts: 60, equipmentType: EquipmentType.lamp),
      ];
      wires = [
        PlcWire(id: 'w1', fromBlockId: 'i1', toBlockId: 't1', toPinIndex: 0),
        PlcWire(id: 'w2', fromBlockId: 't1', toBlockId: 'n1', toPinIndex: 0),
        PlcWire(id: 'w3', fromBlockId: 'n1', toBlockId: 'q1', toPinIndex: 0),
        PlcWire(id: 'w4', fromBlockId: 't1', toBlockId: 'q2', toPinIndex: 0),
        PlcWire(id: 'w5', fromBlockId: 't1', toBlockId: 't2', toPinIndex: 0),
        PlcWire(id: 'w6', fromBlockId: 't2', toBlockId: 'q3', toPinIndex: 0),
      ];
    });
  }

  void _loadAlarmCircuit() {
    if (isSimulating) _toggleSimulation();
    setState(() {
      blocks = [
        PlcBlock(id: 'i1', blockCode: 'I1', type: BlockType.input, label: 'سنسور خطر', x: 30, y: 60, isToggle: false),
        PlcBlock(id: 'i2', blockCode: 'I2', type: BlockType.input, label: 'تایید/ریست', x: 30, y: 170, isToggle: false),
        PlcBlock(id: 'r1', blockCode: 'B001', type: BlockType.rs, label: 'RS', x: 170, y: 100),
        PlcBlock(id: 'p1', blockCode: 'B002', type: BlockType.pulse, label: 'PLS (0.5s)', x: 310, y: 100, param: 0.5),
        PlcBlock(id: 'q1', blockCode: 'Q1', type: BlockType.output, label: 'آژیر/فلاشر', x: 460, y: 100, powerWatts: 100, equipmentType: EquipmentType.lamp),
      ];
      wires = [
        PlcWire(id: 'w1', fromBlockId: 'i1', toBlockId: 'r1', toPinIndex: 0),
        PlcWire(id: 'w2', fromBlockId: 'i2', toBlockId: 'r1', toPinIndex: 1),
        PlcWire(id: 'w3', fromBlockId: 'r1', toBlockId: 'p1', toPinIndex: 0),
        PlcWire(id: 'w4', fromBlockId: 'p1', toBlockId: 'q1', toPinIndex: 0),
      ];
    });
  }

  void _loadWeeklyLightingCircuit() {
    if (isSimulating) _toggleSimulation();
    setState(() {
      blocks = [
        PlcBlock(id: 'b1', blockCode: 'B001', type: BlockType.weeklyTimer, label: 'WEEK (18-6)', x: 40, y: 40, param: 18.0, param2: 6.0),
        PlcBlock(id: 'b2', blockCode: 'I1', type: BlockType.input, label: 'فتوسل', x: 40, y: 150),
        PlcBlock(id: 'b3', blockCode: 'B002', type: BlockType.andGate, label: 'AND', x: 210, y: 90),
        PlcBlock(id: 'b4', blockCode: 'Q1', type: BlockType.output, label: 'روشنایی معابر', x: 380, y: 90, powerWatts: 1000, equipmentType: EquipmentType.lamp),
      ];
      wires = [
        PlcWire(id: 'w1', fromBlockId: 'b1', toBlockId: 'b3', toPinIndex: 0),
        PlcWire(id: 'w2', fromBlockId: 'b2', toBlockId: 'b3', toPinIndex: 1),
        PlcWire(id: 'w3', fromBlockId: 'b3', toBlockId: 'b4', toPinIndex: 0),
      ];
    });
  }

  void _loadBasicCircuit(BlockType gateType, int inCount) {
    if (isSimulating) _toggleSimulation();
    setState(() {
      blocks.clear();
      wires.clear();
      selectedOutputBlockId = null;
      _idCounter = 1;

      if (gateType == BlockType.analogCmp) {
        blocks = [
          PlcBlock(id: 'b1', blockCode: 'AI1', type: BlockType.analogInput, label: 'سنسور دما', x: 40, y: 100, analogVal: 4.5),
          PlcBlock(id: 'b2', blockCode: 'B001', type: BlockType.analogCmp, label: 'A_CMP', x: 200, y: 100, param: 6.0, param2: 4.0),
          PlcBlock(id: 'q1', blockCode: 'Q1', type: BlockType.output, label: 'فن', x: 360, y: 100, powerWatts: 300, equipmentType: EquipmentType.motor),
        ];
        wires = [
          PlcWire(id: 'w1', fromBlockId: 'b1', toBlockId: 'b2', toPinIndex: 0),
          PlcWire(id: 'w2', fromBlockId: 'b2', toBlockId: 'q1', toPinIndex: 0),
        ];
        return;
      }

      for (int i = 0; i < inCount; i++) {
        blocks.add(PlcBlock(
          id: 'i${i + 1}',
          blockCode: 'I${i + 1}',
          type: BlockType.input,
          label: 'I${i + 1}',
          x: 40,
          y: 50.0 + i * 100.0,
        ));
      }
      blocks.add(PlcBlock(
        id: 'g1',
        blockCode: 'B001',
        type: gateType,
        label: gateType.shortName,
        x: 210,
        y: 90,
        param: gateType == BlockType.ctud ? 5.0 : 4.0,
      ));
      blocks.add(PlcBlock(
        id: 'q1',
        blockCode: 'Q1',
        type: BlockType.output,
        label: 'Q1',
        x: 380,
        y: 90,
      ));
      for (int i = 0; i < inCount; i++) {
        wires.add(PlcWire(
          id: 'w${i + 1}',
          fromBlockId: 'i${i + 1}',
          toBlockId: 'g1',
          toPinIndex: i,
        ));
      }
      wires.add(PlcWire(
        id: 'w_out',
        fromBlockId: 'g1',
        toBlockId: 'q1',
        toPinIndex: 0,
      ));
      _idCounter = 20;
    });
  }

  void _openHostShareDialog() {
    final hostCtrl = TextEditingController(text: hostUrl);
    final codeCtrl = TextEditingController();
    String statusMsg = '';
    bool busy = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('ارسال و دریافت نقشه از طریق هاست'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: hostCtrl,
                  decoration: const InputDecoration(
                    labelText: 'آدرس فایل روی هاست (URL)',
                    hintText: 'http://mmm.morningg.ir/circuit_api.php',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'کد نقشه (برای دریافت از گوشی دیگر)',
                    hintText: 'مثلاً 4821 (برای ارسال خالی بگذارید)',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (statusMsg.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SelectableText(
                    statusMsg,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('بستن'),
            ),
            ElevatedButton.icon(
              onPressed: busy
                  ? null
                  : () async {
                      hostUrl = hostCtrl.text.trim();
                      setDlgState(() {
                        busy = true;
                        statusMsg = 'در حال ارسال نقشه...';
                      });
                      try {
                        final client = HttpClient();
                        final req = await client.postUrl(Uri.parse(hostUrl));
                        req.headers.contentType = ContentType.json;
                        final payload = jsonEncode({
                          'blocks': blocks.map((b) => b.toJson()).toList(),
                          'wires': wires.map((w) => w.toJson()).toList(),
                        });
                        req.write(payload);
                        final resp = await req.close();
                        final body = await resp.transform(utf8.decoder).join();
                        final data = jsonDecode(body);
                        setDlgState(() {
                          statusMsg = 'ارسال شد! کد اشتراک: ${data['code']}';
                          codeCtrl.text = data['code'].toString();
                          busy = false;
                        });
                      } catch (e) {
                        setDlgState(() {
                          statusMsg = 'خطا در اتصال به هاست: $e';
                          busy = false;
                        });
                      }
                    },
              icon: const Icon(Icons.cloud_upload, size: 16),
              label: const Text('ارسال نقشه'),
            ),
            ElevatedButton.icon(
              onPressed: busy
                  ? null
                  : () async {
                      hostUrl = hostCtrl.text.trim();
                      final code = codeCtrl.text.trim();
                      if (code.isEmpty) {
                        setDlgState(() => statusMsg = 'کد نقشه را وارد کنید!');
                        return;
                      }
                      setDlgState(() {
                        busy = true;
                        statusMsg = 'در حال دریافت نقشه...';
                      });
                      try {
                        final client = HttpClient();
                        final sep = hostUrl.contains('?') ? '&' : '?';
                        final req = await client.getUrl(
                          Uri.parse('${hostUrl}${sep}code=$code'),
                        );
                        final resp = await req.close();
                        final body = await resp.transform(utf8.decoder).join();
                        final data = jsonDecode(body);
                        if (isSimulating) _toggleSimulation();
                        setState(() {
                          blocks = (data['blocks'] as List)
                              .map((e) => PlcBlock.fromJson(e))
                              .toList();
                          wires = (data['wires'] as List)
                              .map((e) => PlcWire.fromJson(e))
                              .toList();
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setDlgState(() {
                          statusMsg = 'خطا در دریافت نقشه: $e';
                          busy = false;
                        });
                      }
                    },
              icon: const Icon(Icons.cloud_download, size: 16),
              label: const Text('دریافت نقشه'),
            ),
          ],
        ),
      ),
    );
  }

  void _openAiApiDialog() {
    final urlCtrl = TextEditingController(text: aiApiUrl);
    final keyCtrl = TextEditingController(text: aiApiKey);
    final modelCtrl = TextEditingController(text: aiModel);
    final promptCtrl = TextEditingController();
    String status = '';
    bool busy = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('رسم خودکار مدار با هوش مصنوعی (API)'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: urlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'آدرس API (OpenAI / OpenRouter / AvalAI)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: keyCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'کلید API (API Key)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: modelCtrl,
                          decoration: const InputDecoration(
                            labelText: 'مدل (Model)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: promptCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'توضیح مدار را بنویس تا هوش مصنوعی بکشد',
                      hintText: 'مثلاً: مداری بکش که با شستی I1 موتور Q1 روشن شود و بعد از ۶ ثانیه Q2 روشن شود و با I2 قطع شوند',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (status.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(status, style: const TextStyle(fontSize: 11, color: Colors.deepOrange)),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('بستن')),
            ElevatedButton.icon(
              onPressed: busy
                  ? null
                  : () async {
                      aiApiUrl = urlCtrl.text.trim();
                      aiApiKey = keyCtrl.text.trim();
                      aiModel = modelCtrl.text.trim();
                      final userPrompt = promptCtrl.text.trim();
                      if (aiApiKey.isEmpty || userPrompt.isEmpty) {
                        setDlgState(() => status = 'کلید API و توضیح مدار را وارد کنید!');
                        return;
                      }
                      setDlgState(() {
                        busy = true;
                        status = 'در حال اتصال به هوش مصنوعی و طراحی مدار...';
                      });

                      try {
                        final sysPrompt =
                            'You are a Siemens LOGO! Soft Comfort PLC designer. '
                            'Return ONLY valid JSON (no markdown, no explanation) with keys "blocks" and "wires". '
                            'Each block: {"id":"b1","code":"I1","type":"input","label":"I1","x":40,"y":60,"param":3.0,"param2":2.0,"isToggle":true}. '
                            'Allowed types: input, analogInput, output, flag, high, low, andGate, orGate, nandGate, norGate, xorGate, notGate, ton, tof, tonr, tp, pulse, stairway, rs, impulse, ctud, analogCmp, messageText. '
                            'Each wire: {"id":"w1","from":"b1","to":"b2","pin":0}. '
                            'Place inputs at x=40, logic at x=180..360, outputs at x=500, y spaced by 90.';

                        final client = HttpClient();
                        final req = await client.postUrl(Uri.parse(aiApiUrl));
                        req.headers.contentType = ContentType.json;
                        req.headers.set('Authorization', 'Bearer $aiApiKey');
                        req.write(jsonEncode({
                          'model': aiModel,
                          'messages': [
                            {'role': 'system', 'content': sysPrompt},
                            {'role': 'user', 'content': userPrompt},
                          ],
                          'temperature': 0.2,
                        }));
                        final resp = await req.close();
                        final body = await resp.transform(utf8.decoder).join();
                        final decoded = jsonDecode(body);
                        String content = decoded['choices'][0]['message']['content'].toString().trim();
                        if (content.startsWith('```')) {
                          content = content.replaceAll(RegExp(r'^```[a-zA-Z]*\n?'), '').replaceAll(RegExp(r'```$'), '').trim();
                        }
                        final circuit = jsonDecode(content);
                        if (isSimulating) _toggleSimulation();
                        setState(() {
                          blocks = (circuit['blocks'] as List).map((e) => PlcBlock.fromJson(e)).toList();
                          wires = (circuit['wires'] as List).map((e) => PlcWire.fromJson(e)).toList();
                          _idCounter = blocks.length + wires.length + 20;
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setDlgState(() {
                          status = 'خطا: $e';
                          busy = false;
                        });
                      }
                    },
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: const Text('رسم با هوش مصنوعی'),
            ),
          ],
        ),
      ),
    );
  }

  void _openArduinoCodeExportDialog() {
    final sb = StringBuffer();
    sb.writeln('// === Generated by MOHSEN PLC (Arduino / ESP32 C++) ===');
    final inputs = blocks.where((b) => b.type == BlockType.input).toList();
    final analogs = blocks.where((b) => b.type == BlockType.analogInput).toList();
    final outputs = blocks.where((b) => b.type == BlockType.output).toList();

    int pinNum = 2;
    for (final inp in inputs) {
      sb.writeln('const int PIN_${inp.blockCode} = ${pinNum++}; // ${inp.label}');
    }
    int aPin = 0;
    for (final ai in analogs) {
      sb.writeln('const int PIN_${ai.blockCode} = A${aPin++}; // ${ai.label}');
    }
    int outPin = 8;
    for (final out in outputs) {
      sb.writeln('const int PIN_${out.blockCode} = ${outPin++}; // ${out.label}');
    }
    sb.writeln('');
    for (final b in blocks) {
      if (b.type == BlockType.rs || b.type == BlockType.impulse || b.type == BlockType.ton || b.type == BlockType.tof || b.type == BlockType.stairway || b.type == BlockType.ctud) {
        sb.writeln('bool state_${b.id} = false;');
        if (b.type == BlockType.ton || b.type == BlockType.tof || b.type == BlockType.stairway) {
          sb.writeln('unsigned long tStart_${b.id} = 0;');
        }
        if (b.type == BlockType.ctud || b.type == BlockType.impulse) {
          sb.writeln('bool prev_${b.id} = false;');
          if (b.type == BlockType.ctud) sb.writeln('int count_${b.id} = 0;');
        }
      }
    }
    sb.writeln('\nvoid setup() {');
    for (final inp in inputs) {
      sb.writeln('  pinMode(PIN_${inp.blockCode}, INPUT);');
    }
    for (final out in outputs) {
      sb.writeln('  pinMode(PIN_${out.blockCode}, OUTPUT);');
    }
    sb.writeln('}\n\nvoid loop() {');

    final Map<String, PlcBlock> bMap = {for (var b in blocks) b.id: b};
    String exprFor(String id, int depth) {
      if (depth > 12) return 'false';
      final b = bMap[id];
      if (b == null) return 'false';
      String pinExpr(int idx) {
        final w = wires.where((e) => e.toBlockId == b.id && e.toPinIndex == idx);
        if (w.isEmpty) return 'false';
        return exprFor(w.first.fromBlockId, depth + 1);
      }

      List<String> connExprs() {
        final list = <String>[];
        for (int i = 0; i < b.type.inputCount; i++) {
          if (wires.any((e) => e.toBlockId == b.id && e.toPinIndex == i)) {
            list.add(pinExpr(i));
          }
        }
        return list;
      }

      switch (b.type) {
        case BlockType.input:
          return 'digitalRead(PIN_${b.blockCode})';
        case BlockType.high:
          return 'true';
        case BlockType.low:
          return 'false';
        case BlockType.notGate:
          return '(!(${pinExpr(0)}))';
        case BlockType.andGate:
        case BlockType.andEdge:
          final ins = connExprs();
          return ins.isEmpty ? 'false' : '(${ins.join(" && ")})';
        case BlockType.orGate:
          final ins = connExprs();
          return ins.isEmpty ? 'false' : '(${ins.join(" || ")})';
        case BlockType.nandGate:
          final ins = connExprs();
          return ins.isEmpty ? 'true' : '(!(${ins.join(" && ")}))';
        case BlockType.norGate:
          final ins = connExprs();
          return ins.isEmpty ? 'true' : '(!(${ins.join(" || ")}))';
        case BlockType.xorGate:
          return '((${pinExpr(0)}) != (${pinExpr(1)}))';
        case BlockType.rs:
        case BlockType.impulse:
        case BlockType.ton:
        case BlockType.tof:
        case BlockType.stairway:
        case BlockType.ctud:
          return 'state_${b.id}';
        default:
          return pinExpr(0);
      }
    }

    for (final b in blocks) {
      String pinExpr(int idx) {
        final w = wires.where((e) => e.toBlockId == b.id && e.toPinIndex == idx);
        if (w.isEmpty) return 'false';
        return exprFor(w.first.fromBlockId, 0);
      }

      if (b.type == BlockType.rs) {
        sb.writeln('  if (${pinExpr(1)}) state_${b.id} = false; else if (${pinExpr(0)}) state_${b.id} = true;');
      } else if (b.type == BlockType.ton) {
        final ms = (b.param * 1000).toInt();
        sb.writeln('  if (${pinExpr(0)}) { if (tStart_${b.id} == 0) tStart_${b.id} = millis(); state_${b.id} = (millis() - tStart_${b.id} >= ${ms}UL); } else { tStart_${b.id} = 0; state_${b.id} = false; }');
      } else if (b.type == BlockType.tof || b.type == BlockType.stairway) {
        final ms = (b.param * 1000).toInt();
        sb.writeln('  if (${pinExpr(0)}) { state_${b.id} = true; tStart_${b.id} = millis(); } else if (state_${b.id} && millis() - tStart_${b.id} >= ${ms}UL) { state_${b.id} = false; }');
      } else if (b.type == BlockType.impulse) {
        sb.writeln('  { bool trg = ${pinExpr(0)}; if (${pinExpr(1)}) state_${b.id} = false; else if (trg && !prev_${b.id}) state_${b.id} = !state_${b.id}; prev_${b.id} = trg; }');
      } else if (b.type == BlockType.ctud) {
        sb.writeln('  { bool c = ${pinExpr(0)}; if (${pinExpr(2)}) count_${b.id} = 0; else if (c && !prev_${b.id}) count_${b.id}++; prev_${b.id} = c; state_${b.id} = (count_${b.id} >= ${b.param.toInt()}); }');
      }
    }

    for (final out in outputs) {
      final w = wires.where((e) => e.toBlockId == out.id && e.toPinIndex == 0);
      final rhs = w.isEmpty ? 'LOW' : '(${exprFor(w.first.fromBlockId, 0)}) ? HIGH : LOW';
      sb.writeln('  digitalWrite(PIN_${out.blockCode}, $rhs);');
    }
    sb.writeln('}');

    final codeText = sb.toString();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('کد برنامه‌نویسی قطعات (Arduino / ESP32 C++)'),
        content: SizedBox(
          width: 520,
          height: 320,
          child: SingleChildScrollView(
            child: SelectableText(
              codeText,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('بستن')),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: codeText));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('کد آردوینو/میکرو کپی شد!')),
              );
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('کپی کد کامل'),
          ),
        ],
      ),
    );
  }

  void _openCircuitAssistantDialog() {
    final nameCtrl = TextEditingController();
    final detectedName = _identifyDrawnCircuit();
    final quickCircuits = [
      'ستاره مثلث',
      'شستی چندکاره',
      'راه‌پله',
      'روشنایی تبدیل',
      'رله پله‌ای',
      'روشنایی هوشمند هفتگی',
      'استارت استپ موتور',
      'چپ‌گرد راست‌گرد',
      'راه‌اندازی ترتیبی دو موتور',
      'پمپ و مخزن آب',
      'درب پارکینگ',
      'چراغ راهنمایی',
      'دزدگیر و آژیر',
      'تایمر ماندگار قطع برق',
      'شمارنده قطعات',
      'کنترل دما آنالوگ',
      'کنترلر PI',
      'شیفت رجیستر',
      'AND',
      'OR',
      'NAND',
      'NOR',
      'XOR',
      'NOT',
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('دستیار هوشمند مدار (رسم و تشخیص)'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '۱. تشخیص مداری که الان کشیده‌ای:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.teal),
                  ),
                  child: Text(
                    detectedName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const Divider(height: 18),
                const Text(
                  '۲. اسم مدار را بنویس یا از لیست انتخاب کن تا خودش بکشد:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    hintText: 'مثلاً: ستاره مثلث، درب پارکینگ، چراغ راهنمایی، پمپ آب...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: quickCircuits.map((c) {
                    return ActionChip(
                      label: Text(c, style: const TextStyle(fontSize: 10)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _drawCircuitByName(c);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('بستن'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final q = nameCtrl.text;
              Navigator.pop(ctx);
              _drawCircuitByName(q);
            },
            icon: const Icon(Icons.auto_fix_high, size: 16),
            label: const Text('بکش!'),
          ),
        ],
      ),
    );
  }

  // --- 1. Boolean Algebra <-> FBD Converter ---
  String _fbdToBoolean(PlcBlock outBlock) {
    final Map<String, PlcBlock> map = {for (var b in blocks) b.id: b};
    String walk(String id, int depth) {
      if (depth > 10) return '?';
      final b = map[id];
      if (b == null) return '?';
      List<String> ins() {
        final res = <String>[];
        for (int i = 0; i < b.type.inputCount; i++) {
          final w = wires.where((e) => e.toBlockId == b.id && e.toPinIndex == i);
          if (w.isNotEmpty) res.add(walk(w.first.fromBlockId, depth + 1));
        }
        return res;
      }

      switch (b.type) {
        case BlockType.input:
        case BlockType.flag:
          return b.blockCode;
        case BlockType.high:
          return '1';
        case BlockType.low:
          return '0';
        case BlockType.notGate:
          final list = ins();
          return list.isEmpty ? '/?' : '/(${list.first})';
        case BlockType.andGate:
        case BlockType.andEdge:
          final list = ins();
          return list.isEmpty ? '?' : '(${list.join(" · ")})';
        case BlockType.nandGate:
          final list = ins();
          return list.isEmpty ? '?' : '/(${list.join(" · ")})';
        case BlockType.orGate:
          final list = ins();
          return list.isEmpty ? '?' : '(${list.join(" + ")})';
        case BlockType.norGate:
          final list = ins();
          return list.isEmpty ? '?' : '/(${list.join(" + ")})';
        case BlockType.xorGate:
          final list = ins();
          return list.isEmpty ? '?' : '(${list.join(" ⊕ ")})';
        default:
          return b.blockCode;
      }
    }

    final w0 = wires.where((w) => w.toBlockId == outBlock.id && w.toPinIndex == 0);
    if (w0.isEmpty) return '${outBlock.blockCode} = (باز)';
    return '${outBlock.blockCode} = ${walk(w0.first.fromBlockId, 0)}';
  }

  void _buildFbdFromBoolean(String expr) {
    var s = expr.replaceAll(' ', '').toUpperCase();
    if (s.contains('=')) s = s.split('=').last;
    s = s.replaceAll('·', '*').replaceAll('.', '*').replaceAll('!', '/').replaceAll('⊕', '^');
    if (s.isEmpty) return;

    if (isSimulating) _toggleSimulation();
    final List<PlcBlock> newBlocks = [];
    final List<PlcWire> newWires = [];
    final Map<String, PlcBlock> inputCache = {};
    int bIdx = 1;
    int wIdx = 1;
    double gateX = 180;
    double gateY = 60;

    int pos = 0;
    late String Function() parseExpr;

    String getOrCreateInput(String name) {
      if (inputCache.containsKey(name)) return inputCache[name]!.id;
      final idx = inputCache.length;
      final b = PlcBlock(
        id: 'bi_$idx',
        blockCode: name,
        type: BlockType.input,
        label: name,
        x: 30,
        y: 40.0 + idx * 90.0,
      );
      inputCache[name] = b;
      newBlocks.add(b);
      return b.id;
    }

    String makeGate(BlockType type, List<String> childIds) {
      final id = 'bg_${bIdx++}';
      final code = 'B${bIdx.toString().padLeft(3, '0')}';
      newBlocks.add(PlcBlock(
        id: id,
        blockCode: code,
        type: type,
        label: type.shortName,
        x: gateX,
        y: gateY,
      ));
      gateX += 115;
      if (gateX > 460) {
        gateX = 180;
        gateY += 95;
      }
      for (int i = 0; i < childIds.length && i < type.inputCount; i++) {
        newWires.add(PlcWire(
          id: 'bw_${wIdx++}',
          fromBlockId: childIds[i],
          toBlockId: id,
          toPinIndex: i,
        ));
      }
      return id;
    }

    String parseFactor() {
      if (pos < s.length && s[pos] == '/') {
        pos++;
        final inner = parseFactor();
        return makeGate(BlockType.notGate, [inner]);
      }
      if (pos < s.length && s[pos] == '(') {
        pos++;
        final inner = parseExpr();
        if (pos < s.length && s[pos] == ')') pos++;
        return inner;
      }
      final start = pos;
      while (pos < s.length && RegExp(r'[A-Z0-9]').hasMatch(s[pos])) {
        pos++;
      }
      final token = s.substring(start, pos);
      return getOrCreateInput(token.isEmpty ? 'I1' : token);
    }

    String parseTerm() {
      var left = parseFactor();
      while (pos < s.length && (s[pos] == '*' || s[pos] == '^')) {
        final op = s[pos++];
        final right = parseFactor();
        left = makeGate(op == '^' ? BlockType.xorGate : BlockType.andGate, [left, right]);
      }
      return left;
    }

    parseExpr = () {
      var left = parseTerm();
      while (pos < s.length && s[pos] == '+') {
        pos++;
        final right = parseTerm();
        left = makeGate(BlockType.orGate, [left, right]);
      }
      return left;
    };

    try {
      final rootId = parseExpr();
      final q1 = PlcBlock(
        id: 'bq1',
        blockCode: 'Q1',
        type: BlockType.output,
        label: 'Q1',
        x: math.max(gateX, 420),
        y: 100,
      );
      newBlocks.add(q1);
      newWires.add(PlcWire(id: 'bw_q', fromBlockId: rootId, toBlockId: q1.id, toPinIndex: 0));
      setState(() {
        blocks = newBlocks;
        wires = newWires;
        _idCounter = 100;
      });
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فرمول بولی نامعتبر است! مثال: Q1 = (I1 + I2) * /I3')),
      );
    }
  }

  void _openBooleanDialog() {
    final exprCtrl = TextEditingController(text: 'Q1 = (I1 + I2) * /I3');
    final outputs = blocks.where((b) => b.type == BlockType.output).toList();
    final formulas = outputs.map((q) => _fbdToBoolean(q)).join('\n');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تبدیل فرمول بولی ↔ نقشه FBD'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('معادله بولی مدار فعلی:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: const Color(0xFFE0F2F1),
                  child: SelectableText(
                    formulas.isEmpty ? 'خروجی Q در مدار وجود ندارد.' : formulas,
                    style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(height: 18),
                const Text('تبدیل معادله بولی به نقشه (+ برای OR، * برای AND، / برای NOT):',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange, fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: exprCtrl,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Q1 = (I1 + I2) * /I3',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('بستن')),
          ElevatedButton(
            onPressed: () {
              final text = exprCtrl.text;
              Navigator.pop(ctx);
              _buildFbdFromBoolean(text);
            },
            child: const Text('تبدیل به نقشه FBD'),
          ),
        ],
      ),
    );
  }

  // --- 2. Electrical & Electronics Calculator (Resistor Color, Ohm, 3-Phase, PF Cap) ---
  void _openElectricalCalculatorDialog() {
    final colors = [
      {'name': 'سیاه (0)', 'val': 0, 'mult': 1.0, 'col': Colors.black},
      {'name': 'قهوه‌ای (1)', 'val': 1, 'mult': 10.0, 'col': Colors.brown},
      {'name': 'قرمز (2)', 'val': 2, 'mult': 100.0, 'col': Colors.red},
      {'name': 'نارنجی (3)', 'val': 3, 'mult': 1000.0, 'col': Colors.orange},
      {'name': 'زرد (4)', 'val': 4, 'mult': 10000.0, 'col': Colors.yellow},
      {'name': 'سبز (5)', 'val': 5, 'mult': 100000.0, 'col': Colors.green},
      {'name': 'آبی (6)', 'val': 6, 'mult': 1000000.0, 'col': Colors.blue},
      {'name': 'بنفش (7)', 'val': 7, 'mult': 10000000.0, 'col': Colors.purple},
      {'name': 'خاکستری (8)', 'val': 8, 'mult': 1.0, 'col': Colors.grey},
      {'name': 'سفید (9)', 'val': 9, 'mult': 1.0, 'col': Colors.white},
    ];
    int b1 = 1, b2 = 0, b3 = 2; // default 1k Ohm (Brown, Black, Red)
    final vCtrl = TextEditingController(text: '380');
    final iCtrl = TextEditingController(text: '10');
    final cosCtrl = TextEditingController(text: '0.8');
    final pKwCtrl = TextEditingController(text: '10');
    final cos1Ctrl = TextEditingController(text: '0.7');
    final cos2Ctrl = TextEditingController(text: '0.95');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final rVal = ((colors[b1]['val'] as int) * 10 + (colors[b2]['val'] as int)) *
              (colors[b3]['mult'] as double);
          final rStr = rVal >= 1000000
              ? '${(rVal / 1000000).toStringAsFixed(2)} MΩ'
              : (rVal >= 1000 ? '${(rVal / 1000).toStringAsFixed(2)} kΩ' : '${rVal.toStringAsFixed(0)} Ω');

          final v = double.tryParse(vCtrl.text) ?? 0;
          final amp = double.tryParse(iCtrl.text) ?? 0;
          final cosphi = (double.tryParse(cosCtrl.text) ?? 0.8).clamp(0.1, 1.0);
          final p1 = v * amp * cosphi;
          final p3 = 1.732 * v * amp * cosphi;

          final pKw = double.tryParse(pKwCtrl.text) ?? 0;
          final c1 = (double.tryParse(cos1Ctrl.text) ?? 0.7).clamp(0.1, 0.99);
          final c2 = (double.tryParse(cos2Ctrl.text) ?? 0.95).clamp(0.1, 1.0);
          final qc = pKw * (math.tan(math.acos(c1)) - math.tan(math.acos(c2)));

          return AlertDialog(
            title: const Text('ماشین‌حساب تخصصی برق و الکترونیک'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('۱. کد رنگ مقاومت:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButton<int>(
                            isExpanded: true,
                            value: b1,
                            items: List.generate(10, (i) => DropdownMenuItem(value: i, child: Text(colors[i]['name'] as String, style: const TextStyle(fontSize: 11)))),
                            onChanged: (val) => setDlgState(() => b1 = val ?? 1),
                          ),
                        ),
                        Expanded(
                          child: DropdownButton<int>(
                            isExpanded: true,
                            value: b2,
                            items: List.generate(10, (i) => DropdownMenuItem(value: i, child: Text(colors[i]['name'] as String, style: const TextStyle(fontSize: 11)))),
                            onChanged: (val) => setDlgState(() => b2 = val ?? 0),
                          ),
                        ),
                        Expanded(
                          child: DropdownButton<int>(
                            isExpanded: true,
                            value: b3,
                            items: List.generate(8, (i) => DropdownMenuItem(value: i, child: Text(colors[i]['name'] as String, style: const TextStyle(fontSize: 11)))),
                            onChanged: (val) => setDlgState(() => b3 = val ?? 2),
                          ),
                        ),
                      ],
                    ),
                    Text('مقدار مقاومت: $rStr (±5%)', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                    const Divider(),
                    const Text('۲. قانون اهم و توان تک‌فاز / سه‌فاز:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: vCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'ولتاژ V'), onChanged: (_) => setDlgState(() {}))),
                        const SizedBox(width: 6),
                        Expanded(child: TextField(controller: iCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'جریان A'), onChanged: (_) => setDlgState(() {}))),
                        const SizedBox(width: 6),
                        Expanded(child: TextField(controller: cosCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'cosφ'), onChanged: (_) => setDlgState(() {}))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('تک‌فاز: ${p1.toStringAsFixed(0)} W | سه‌فاز: ${(p3 / 1000).toStringAsFixed(2)} kW | R=${amp > 0 ? (v / amp).toStringAsFixed(1) : 0} Ω',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const Divider(),
                    const Text('۳. خازن اصلاح ضریب قدرت (kVAR):', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: pKwCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'توان kW'), onChanged: (_) => setDlgState(() {}))),
                        const SizedBox(width: 6),
                        Expanded(child: TextField(controller: cos1Ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'cosφ فعلی'), onChanged: (_) => setDlgState(() {}))),
                        const SizedBox(width: 6),
                        Expanded(child: TextField(controller: cos2Ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'cosφ هدف'), onChanged: (_) => setDlgState(() {}))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('ظرفیت بانک خازنی مورد نیاز: ${qc.toStringAsFixed(2)} kVAR',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('بستن')),
            ],
          );
        },
      ),
    );
  }

  // --- 3. Local Phone Project Storage (No external plugins) ---
  Directory _getLocalProjectsDir() {
    final appDir = Directory('/data/data/com.mohsen.plc/files/mohsen_projects');
    if (appDir.parent.existsSync()) {
      if (!appDir.existsSync()) appDir.createSync(recursive: true);
      return appDir;
    }
    final tmp = Directory('${Directory.systemTemp.path}/mohsen_projects');
    if (!tmp.existsSync()) tmp.createSync(recursive: true);
    return tmp;
  }

  void _openLocalProjectsDialog() {
    final nameCtrl = TextEditingController();
    final dir = _getLocalProjectsDir();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final files = dir
              .listSync()
              .whereType<File>()
              .where((f) => f.path.endsWith('.json'))
              .toList();

          return AlertDialog(
            title: const Text('ذخیره و مدیریت پروژه‌ها در حافظه گوشی'),
            content: SizedBox(
              width: 460,
              height: 300,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(
                            hintText: 'نام پروژه جدید (مثلاً: موتور_ستاره)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: () {
                          final n = nameCtrl.text.trim().replaceAll('/', '_');
                          if (n.isEmpty) return;
                          final f = File('${dir.path}/$n.json');
                          f.writeAsStringSync(jsonEncode({
                            'blocks': blocks.map((b) => b.toJson()).toList(),
                            'wires': wires.map((w) => w.toJson()).toList(),
                          }));
                          nameCtrl.clear();
                          setDlgState(() {});
                        },
                        child: const Text('ذخیره'),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: files.isEmpty
                        ? const Center(child: Text('هنوز پروژه‌ای در حافظه ذخیره نشده است.'))
                        : ListView.builder(
                            itemCount: files.length,
                            itemBuilder: (_, i) {
                              final f = files[i];
                              final fname = f.uri.pathSegments.last.replaceAll('.json', '');
                              return ListTile(
                                dense: true,
                                title: Text(fname, style: const TextStyle(fontWeight: FontWeight.bold)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.folder_open, color: Colors.teal),
                                      onPressed: () {
                                        final data = jsonDecode(f.readAsStringSync());
                                        if (isSimulating) _toggleSimulation();
                                        setState(() {
                                          blocks = (data['blocks'] as List).map((e) => PlcBlock.fromJson(e)).toList();
                                          wires = (data['wires'] as List).map((e) => PlcWire.fromJson(e)).toList();
                                        });
                                        Navigator.pop(ctx);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        f.deleteSync();
                                        setDlgState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('بستن')),
            ],
          );
        },
      ),
    );
  }

  // --- 4. Real Siemens LOGO! 12/24RCE Hardware Wiring View ---
  Widget _buildHardwareLogoView() {
    final inputs = blocks.where((b) => b.type == BlockType.input).toList();
    final outputs = blocks.where((b) => b.type == BlockType.output).toList();
    final activeMsg = isSimulating
        ? blocks.where((b) => b.type == BlockType.messageText && b.value).toList()
        : <PlcBlock>[];

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF263238),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Screw Terminals: L+, M, I1..I8
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _terminalBadge('L+', !isPowerOutage && isSimulating, Colors.red),
                  _terminalBadge('M', !isPowerOutage && isSimulating, Colors.blue),
                  for (int i = 0; i < 8; i++)
                    _terminalBadge(
                      'I${i + 1}',
                      i < inputs.length && isSimulating && inputs[i].value,
                      Colors.amber,
                      onTap: (isSimulating && i < inputs.length)
                          ? () => setState(() => inputs[i].value = !inputs[i].value)
                          : null,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // LOGO! Backlit LCD Screen
                  Expanded(
                    flex: 3,
                    child: Container(
                      height: 115,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (!isPowerOutage && isSimulating)
                            ? const Color(0xFFFFCA28)
                            : const Color(0xFF90A4AE),
                        border: Border.all(color: Colors.black, width: 2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('SIEMENS LOGO! 12/24RCE',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87)),
                          Text(
                            activeMsg.isNotEmpty
                                ? activeMsg.first.messageText
                                : (isSimulating ? 'RUN MODE (MOHSEN)' : 'STOP / EDIT'),
                            style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black),
                          ),
                          Text(
                            'I: ${List.generate(8, (i) => (i < inputs.length && inputs[i].value) ? "1" : "0").join("")}',
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black87),
                          ),
                          Text(
                            'Q: ${List.generate(4, (i) => (i < outputs.length && outputs[i].value) ? "1" : "0").join("")}',
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Keypad Buttons (ESC, OK, Arrows)
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade700,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.arrow_drop_up, color: Colors.white),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(Icons.arrow_left, color: Colors.white),
                                  Icon(Icons.arrow_right, color: Colors.white),
                                ],
                              ),
                              Icon(Icons.arrow_drop_down, color: Colors.white),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              color: Colors.grey.shade400,
                              child: const Text('ESC', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black)),
                            ),
                            InkWell(
                              onTap: _toggleSimulation,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                color: Colors.green,
                                child: const Text('OK', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Bottom Relay Output Terminals: Q1..Q4
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (int i = 0; i < 4; i++)
                    _terminalBadge(
                      'Q${i + 1} (10A)',
                      i < outputs.length && isSimulating && outputs[i].value,
                      Colors.lightGreenAccent,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _terminalBadge(String label, bool active, Color activeColor, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
        decoration: BoxDecoration(
          color: active ? activeColor : const Color(0xFF37474F),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: Colors.white30),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: active ? Colors.black : Colors.white70,
          ),
        ),
      ),
    );
  }

  void _openComponentEncyclopediaDialog() {
    final searchCtrl = TextEditingController();

    final Map<String, Map<String, String>> componentsDb = {
      'مقاومت (Resistor)': {
        'keys': 'مقاومت resistor اهم r',
        'desc': 'قطعه پسیو برای محدود کردن جریان و تقسیم ولتاژ در مدارهای الکترونیکی. واحد آن اهم (Ω) است و روی بدنه آن نوارهای رنگی برای خواندن مقدار وجود دارد.',
        'use': 'محافظت از LED، بایاس ترانزیستور و تقسیم ولتاژ. تست با مولتی‌متر روی رنج اهم (Ω).',
      },
      'خازن (Capacitor)': {
        'keys': 'خازن capacitor فاراد c',
        'desc': 'قطعه ذخیره‌کننده انرژی الکتریکی در میدان الکتریکی بین دو صفحه رسانا. واحد آن فاراد (معمولاً میکروفاراد µF یا پیکوفاراد pF) است.',
        'use': 'صافی ولتاژ در منابع تغذیه، حذف نویز، جبران‌سازی ضریب قدرت و راه‌اندازی موتور تک‌فاز.',
      },
      'سلف / القاگر (Inductor)': {
        'keys': 'سلف القاگر بوبین چوک inductor coil l',
        'desc': 'سیم‌پیچی است که انرژی را در میدان مغناطیسی ذخیره می‌کند و در برابر تغییرات ناگهانی جریان مقاومت نشان می‌دهد. واحد آن هانری (H) است.',
        'use': 'فیلترهای فرکانسی، منابع تغذیه سوئیچینگ، مبدل‌ها و بالاست مهتابی.',
      },
      'دیود (Diode)': {
        'keys': 'دیود یکسوساز diode 1n4007',
        'desc': 'قطعه نیمه‌هادی دوپایه (آند و کاتد) که جریان الکتریکی را فقط در یک جهت عبور می‌دهد و در جهت مخالف مسدود می‌کند.',
        'use': 'یکسوسازی برق AC به DC و حفاظت از مدار در برابر پلاریته معکوس. تست با حالت دیود مولتی‌متر.',
      },
      'دیود زنر (Zener Diode)': {
        'keys': 'زنر zener دیود تثبیت',
        'desc': 'دیود خاصی که در بایاس معکوس روی یک ولتاژ مشخص (ولتاژ زنر) ثابت می‌ماند و اجازه عبور جریان را می‌دهد.',
        'use': 'تثبیت ولتاژ مرجع و حفاظت از ورودی آی‌سی‌ها در برابر اضافه‌ولتاژ.',
      },
      'پل دیود (Bridge Rectifier)': {
        'keys': 'پل دیود bridge یکسوساز',
        'desc': 'مجموعه ۴ دیود در یک پکیج که هر دو نیم‌سیکل مثبت و منفی برق متناوب (AC) را به برق مستقیم (DC) تمام‌موج تبدیل می‌کند.',
        'use': 'ورودی منابع تغذیه، آداپتورها و شارژرها.',
      },
      'دیود نوری (LED)': {
        'keys': 'ال ای دی led دیود نوری چراغ',
        'desc': 'دیود نیمه‌هادی که با عبور جریان در جهت مستقیم، نور ساطع می‌کند و حتماً باید با یک مقاومت سری بسته شود.',
        'use': 'چراغ سیگنال، نمایشگر وضعیت و روشنایی.',
      },
      'ترانزیستور (BJT)': {
        'keys': 'ترانزیستور transistor bjt npn pnp',
        'desc': 'قطعه نیمه‌هادی سه‌پایه (بیس، کلکتور، امیتر) در دو نوع NPN و PNP که با جریان کوچک پایه بیس، جریان بزرگ کلکتور-امیتر را کنترل می‌کند.',
        'use': 'تقویت‌کننده سیگنال و کلیدزنی (سوئیچینگ) بارهای DC و بوبین رله.',
      },
      'ماسفت (MOSFET)': {
        'keys': 'ماسفت mosfet fet ترانزیستور قدرت',
        'desc': 'ترانزیستور اثر میدانی کنترل‌شده با ولتاژ (گیت، درین، سورس) با مقاومت هدایتی بسیار کم و سرعت سوئیچینگ بسیار بالا.',
        'use': 'درایور موتور، اینورترها، منابع تغذیه سوئیچینگ و کنترلرهای PWM.',
      },
      'تریستور (SCR)': {
        'keys': 'تریستور thyristor scr',
        'desc': 'کلید نیمه‌هادی قدرت سه‌پایه (آند، کاتد، گیت) که با پالس لحظه‌ای گیت روشن می‌شود و تا صفر شدن جریان آند روشن می‌ماند.',
        'use': 'یکسوسازهای کنترل‌شده، دیمرهای قدرت و کنترل دور موتورهای DC.',
      },
      'ترایاک (TRIAC)': {
        'keys': 'ترایاک triac دیمر',
        'desc': 'معادل دو تریستور موازی-معکوس که قابلیت هدایت و کنترل جریان در هر دو جهت برق متناوب (AC) را دارد.',
        'use': 'دیمر لامپ، کنترل سرعت فن AC و کنترل حرارت هیترها.',
      },
      'رگولاتور ولتاژ (7805 / LM317)': {
        'keys': 'رگولاتور regulator 7805 7812 lm317 تثبیت',
        'desc': 'آی‌سی تثبیت‌کننده ولتاژ خطی که ولتاژ ورودی متغیر DC را به یک ولتاژ خروجی کاملاً ثابت (مثلاً ۵ یا ۱۲ ولت) تبدیل می‌کند.',
        'use': 'تغذیه پایدار میکروکنترلرها، سنسورها و مدارات منطقی.',
      },
      'آپ‌امپ (Op-Amp / LM358)': {
        'keys': 'اپ امپ آپ امپ opamp lm358 تقویت کننده عملیاتی',
        'desc': 'تقویت‌کننده تفاضلی با بهره بسیار بالا که اختلاف ولتاژ دو ورودی مثبت و منفی را تقویت یا مقایسه می‌کند.',
        'use': 'مقایسه‌گر آنالوگ، تقویت سیگنال سنسورها و فیلترهای فعال.',
      },
      'آی‌سی تایمر ۵۵۵ (NE555)': {
        'keys': '555 ۵۵۵ تایمر آی سی',
        'desc': 'آی‌سی پرکاربرد تولید پالس، تاخیر زمانی و نوسان‌ساز (Astable / Monostable).',
        'use': 'ساخت چشمک‌زن، پالس‌ساز PWM و تایمرهای ساده الکترونیکی.',
      },
      'اپتوکوپلر (Optocoupler / PC817)': {
        'keys': 'اپتوکوپلر optocoupler ایزولاتور pc817',
        'desc': 'قطعه ایزوله‌کننده نوری شامل یک LED و یک فوتوترانزیستور در یک پکیج که ارتباط سیگنال را بدون اتصال الکتریکی مستقیم برقرار می‌کند.',
        'use': 'جداسازی مدار فرمان حساس (مثل میکرو یا PLC) از مدار قدرت ولتاژ بالا.',
      },
      'پتانسیومتر (Potentiometer)': {
        'keys': 'پتانسیومتر ولوم مقاومت متغیر pot',
        'desc': 'مقاومت متغیر سه‌پایه با محور چرخان یا کشویی که برای تغییر پیوسته ولتاژ یا مقاومت استفاده می‌شود.',
        'use': 'تنظیم ولتاژ مرجع، کنترل سرعت، ولوم صدا و ورودی آنالوگ آزمایشی.',
      },
      'فتوسل / مقاومت نوری (LDR)': {
        'keys': 'فتوسل ldr سنسور نور نوری',
        'desc': 'مقاومتی که مقدار آن با افزایش شدت نور کاهش می‌یابد و برای تشخیص تاریکی یا روشنایی محیط به کار می‌رود.',
        'use': 'روشن و خاموش کردن خودکار چراغ معابر، حیاط و روشنایی هوشمند.',
      },
      'ترمیستور (NTC / PTC)': {
        'keys': 'ترمیستور ntc ptc سنسور دما حرارتی',
        'desc': 'مقاومت حساس به دما؛ در NTC با افزایش دما مقاومت کم می‌شود و در PTC با افزایش دما مقاومت زیاد می‌شود.',
        'use': 'اندازه‌گیری دما، حفاظت سیم‌پیچ موتور و محدودکننده جریان هجومی.',
      },
      'سنسور دما PT100': {
        'keys': 'pt100 سنسور دما رزیستنس ترموکوپل',
        'desc': 'سنسور دمای مقاومتی پلاتینی بسیار دقیق صنعتی که در دمای صفر درجه سانتی‌گراد دقیقاً ۱۰۰ اهم مقاومت دارد.',
        'use': 'کنترل دمای کوره‌های صنعتی و اتصال به ماژول آنالوگ PLC لوگو (مبحث پودمان ۴ کتاب).',
      },
      'کنتاکتور (Contactor)': {
        'keys': 'کنتاکتور contactor بوبین تیغه قدرت',
        'desc': 'کلید الکترومغناطیسی قدرت برای قطع و وصل بارهای سه‌فاز و پرجریان از راه دور. دارای بوبین فرمان (A1/A2)، تیغه‌های قدرت (L1..T3) و تیغه‌های کمکی (NO/NC).',
        'use': 'راه‌اندازی موتورهای الکتریکی، ستاره-مثلث و چپ‌گرد/راست‌گرد.',
      },
      'بیمتال / رله حرارتی (Thermal Overload)': {
        'keys': 'بیمتال رله حرارتی overload اضافه بار',
        'desc': 'تجهیز حفاظتی متشکل از تیغه دو فلزه که در صورت کشیدن جریان بیش از حد مجاز توسط موتور، گرم شده، خم می‌شود و مدار فرمان کنتاکتور را قطع می‌کند.',
        'use': 'حفاظت موتورهای سه‌فاز و تک‌فاز در برابر اضافه‌بار و دو فاز شدن.',
      },
      'کلید مینیاتوری (MCB)': {
        'keys': 'مینیاتوری mcb فیوز کلید حفاظتی',
        'desc': 'کلید اتوماتیک حفاظتی که از سیم‌کشی و تجهیزات در برابر اتصال کوتاه (حفاظت مغناطیسی) و اضافه‌بار (حفاظت حرارتی) محافظت می‌کند. تیپ B برای روشنایی و تیپ C برای موتور است.',
        'use': 'حفاظت مدارهای روشنایی، پریزها و تابلوهای فرمان.',
      },
      'کلید محافظ جان (RCCB / RCD)': {
        'keys': 'محافظ جان rccb rcd نشتی جریان',
        'desc': 'کلیدی که اختلاف جریان رفت و برگشت (جریان نشتی به زمین، معمولاً ۳۰ میلی‌آمپر) را تشخیص داده و مدار را در کسری از ثانیه قطع می‌کند.',
        'use': 'جلوگیری از برق‌گرفتگی افراد و حفاظت در برابر آتش‌سوزی ناشی از نشتی.',
      },
      'رله شیشه‌ای / کمکی (Relay)': {
        'keys': 'رله کمکی شیشه ای relay',
        'desc': 'کلید الکترومغناطیسی کوچک برای ایزوله کردن خروجی PLC یا تغییر ولتاژ فرمان (مثلاً تبدیل فرمان ۲۴ ولت به ۲۲۰ ولت).',
        'use': 'واسط بین خروجی رله‌ای PLC و کنتاکتورها یا لامپ‌ها.',
      },
      'لیمیت سوئیچ (Limit Switch)': {
        'keys': 'لیمیت سوئیچ میکروسوئیچ انتهایی',
        'desc': 'کلید مکانیکی اهرمی یا غلطکی که با برخورد فیزیکی قطعه یا درب متحرک، تغییر وضعیت (NO/NC) می‌دهد.',
        'use': 'تشخیص رسیدن درب پارکینگ یا آسانسور به نقطه انتهایی باز یا بسته.',
      },
      'سنسور القایی (Proximity Sensor)': {
        'keys': 'سنسور القایی مجاورتی proximity pnp npn',
        'desc': 'سنسور بدون تماس که با نزدیک شدن اجسام فلزی به سطح حسگر، خروجی ۲۴ ولت DC (در دو نوع PNP و NPN) ارسال می‌کند.',
        'use': 'شمارش قطعات فلزی روی نوار نقاله و اتصال به ورودی دیجیتال PLC.',
      },
      'رله قابل برنامه‌ریزی (LOGO! PLC)': {
        'keys': 'لوگو پی ال سی plc logo زیمنس',
        'desc': 'کنترلر منطقی قابل برنامه‌ریزی زیمنس (موضوع کتاب ۲۱۲۲۶۶) با ورودی‌های دیجیتال/آنالوگ (I/AI) و خروجی‌های رله‌ای (Q) که جایگزین مدارات فرمان سیم‌کشی‌شده سنتی می‌شود.',
        'use': 'اتوماسیون روشنایی، راه‌اندازی موتورها، کنترل تاسیسات و سیستم‌های هوشمند.',
      },
    };

    String query = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final matches = componentsDb.entries.where((e) {
            if (query.trim().isEmpty) return true;
            final q = query.trim().toLowerCase();
            return e.key.toLowerCase().contains(q) ||
                e.value['keys']!.toLowerCase().contains(q) ||
                e.value['desc']!.toLowerCase().contains(q);
          }).toList();

          return AlertDialog(
            title: const Text('مرجع و راهنمای قطعات الکترونیکی و برقی'),
            content: SizedBox(
              width: 500,
              height: 360,
              child: Column(
                children: [
                  TextField(
                    controller: searchCtrl,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'نام قطعه را بنویسید (مقاومت، خازن، ترانزیستور، کنتاکتور، بیمتال...)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => setDlgState(() => query = v),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: matches.isEmpty
                        ? const Center(
                            child: Text('قطعه مورد نظر پیدا نشد! نام دیگری وارد کنید.'),
                          )
                        : ListView.separated(
                            itemCount: matches.length,
                            separatorBuilder: (_, __) => const Divider(height: 10),
                            itemBuilder: (_, idx) {
                              final entry = matches[idx];
                              return Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.black12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.key,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Color(0xFF00695C),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      entry.value['desc']!,
                                      style: const TextStyle(fontSize: 11, height: 1.4),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'کاربرد و تست: ${entry.value['use']!}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.deepOrange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('بستن'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _explainCurrentCircuit() {
    if (blocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('صفحه خالی است — ابتدا یک مدار رسم یا انتخاب کنید.')),
      );
      return;
    }

    final title = _identifyDrawnCircuit();
    final types = blocks.map((b) => b.type).toSet();
    final outCount = blocks.where((b) => b.type == BlockType.output).length;
    final stwCount = blocks.where((b) => b.type == BlockType.stairway).length;
    final rsCount = blocks.where((b) => b.type == BlockType.rs).length;
    final notCount = blocks.where((b) => b.type == BlockType.notGate).length;

    String howItWorks = '';
    if (stwCount >= 3 && outCount >= 4) {
      howItWorks =
          'با زدن شستی I1، راهرو همکف (Q1) فوراً روشن می‌شود. اگر شستی I1 به اندازه زمان تایمر B008 (۵ ثانیه) نگه داشته شود، خروجی B008 از طریق گیت‌های OR تمام تایمرهای راه‌پله (Q2، Q3 و Q4) را با هم روشن می‌کند؛ همچنین شستی‌های I2، I3 و I4 هر طبقه را به‌صورت مستقل روشن می‌کنند.';
    } else if (types.contains(BlockType.rs) &&
        types.contains(BlockType.ton) &&
        types.contains(BlockType.notGate) &&
        outCount >= 3) {
      howItWorks =
          'با زدن شستی Start (I1)، رله RS فعال شده و کنتاکتور اصلی (Q1) و ستاره (Q2) موتور را با جریان راه‌اندازی کم به حرکت درمی‌آورند. هم‌زمان تایمر TON شروع به شمارش می‌کند و پس از رسیدن به زمان تنظیم‌شده، گیت NOT خروجی ستاره (Q2) را قطع و خروجی مثلث (Q3) را وصل می‌کند. با زدن Stop کل مدار متوقف می‌شود.';
    } else if (rsCount >= 2 && notCount >= 2) {
      howItWorks =
          'این مدار دارای اینترلاک حفاظتی (گیت‌های NOT و AND) است؛ یعنی تا زمانی که موتور در جهت راست‌گرد (Q1) کار می‌کند، مسیر چپ‌گرد (Q2) قفل است و برعکس، تا از اتصال کوتاه دو فاز جلوگیری شود.';
    } else if (rsCount >= 2 && notCount == 0) {
      howItWorks =
          'هشدار: در این مدار دو رله RS بدون گیت NOT و AND اینترلاک بسته شده‌اند؛ در صورت زدن هم‌زمان I1 و I2 هر دو خروجی Q1 و Q2 با هم فعال می‌شوند که خطر اتصال کوتاه دارد.';
    } else if (types.contains(BlockType.xorGate)) {
      howItWorks =
          'گیت XOR زمانی خروجی (Q1) را فعال می‌کند که وضعیت دو ورودی I1 و I2 با هم متفاوت باشد (یکی ۱ و دیگری ۰)؛ بنابراین از هر دو کلید می‌توان لامپ را روشن یا خاموش کرد (مدار تبدیل).';
    } else if (types.contains(BlockType.stairway) || types.contains(BlockType.tof)) {
      howItWorks =
          'با زدن هر یک از شستی‌های ورودی، تایمر راه‌پله/قطع‌کن (TOF/STW) خروجی روشنایی را به مدت زمان تنظیم‌شده (T) روشن نگه می‌دارد و پس از اتمام زمان به‌صورت خودکار خاموش می‌کند.';
    } else if (types.contains(BlockType.impulse)) {
      howItWorks =
          'رله پله‌ای (Impulse) با هر بار دریافت پالس لحظه‌ای از ورودی اول، وضعیت خروجی را برعکس می‌کند (یک‌بار روشن، بار بعد خاموش) و با پایه Reset خاموش می‌شود.';
    } else if (types.contains(BlockType.weeklyTimer)) {
      howItWorks =
          'تایمر هفتگی در بازه ساعتی تنظیم‌شده (مثلاً ۱۸ تا ۶ صبح) خروجی خود را ۱ می‌کند و در ترکیب با گیت AND و سنسور فتوسل، روشنایی معابر را هوشمند کنترل می‌کند.';
    } else if (types.contains(BlockType.notGate) && types.contains(BlockType.rs)) {
      howItWorks =
          'وقتی آب مخزن پایین برود (I1=0)، گیت NOT خروجی ۱ داده و رله RS پمپ (Q1) را روشن می‌کند؛ وقتی آب به سنسور بالا (I2=1) برسد، پایه Reset فعال شده و پمپ خاموش می‌شود.';
    } else if (types.contains(BlockType.rs)) {
      howItWorks =
          'با زدن شستی Set (ورودی اول)، رله RS حافظه‌دار می‌شود و خروجی حتی پس از رها کردن شستی روشن می‌ماند تا زمانی که شستی Reset (ورودی دوم) زده شود.';
    } else if (types.contains(BlockType.analogInput) && types.contains(BlockType.analogCmp)) {
      howItWorks =
          'سیگنال آنالوگ (۰ تا ۱۰ ولت) وارد مقایسه‌گر می‌شود؛ هرگاه مقدار آن به آستانه وصل (On) برسد خروجی روشن شده و تا پایین آمدن زیر آستانه قطع (Off) روشن می‌ماند.';
    } else if (types.contains(BlockType.ctud)) {
      howItWorks =
          'شمارنده بالا/پایین با هر لبه بالارونده ورودی اول (Cnt) یک واحد می‌شمارد و وقتی تعداد به مقدار هدف (PV) برسد، خروجی را فعال می‌کند؛ با پایه R شمارنده صفر می‌شود.';
    } else if (types.contains(BlockType.tonr)) {
      howItWorks =
          'تایمر ماندگار (TONR) زمان سپری‌شده را حتی در صورت قطع برق یا قطع ورودی در حافظه نگه می‌دارد و فقط با فعال شدن پایه Reset (R) صفر می‌شود.';
    } else if (types.contains(BlockType.pulse)) {
      howItWorks =
          'پالس‌ساز متناوب (Async Pulse) تا زمانی که ورودی تحریک فعال است، خروجی را به‌طور منظم با بازه زمانی تنظیم‌شده روشن و خاموش (چشمک‌زن) می‌کند.';
    } else {
      howItWorks =
          'سیگنال از بلوک‌های ورودی عبور کرده، طبق منطق گیت‌های متصل‌شده پردازش می‌شود و نتیجه نهایی در بلوک‌های خروجی ظاهر می‌گردد.';
    }

    final List<String> blockDetails = [];
    for (final b in blocks) {
      final incoming = wires.where((w) => w.toBlockId == b.id).map((w) {
        final src = blocks.firstWhere((e) => e.id == w.fromBlockId, orElse: () => b);
        return '${src.blockCode} (${src.label})';
      }).toList();
      final srcText = incoming.isEmpty ? 'بدون ورودی متصل' : 'متصل به: ${incoming.join("، ")}';
      blockDetails.add('• ${b.blockCode} [${b.type.title}] — ${b.label}\n   $srcText');
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('توضیح عملکرد مدار'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2F1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.teal),
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 10),
                const Text('نحوه کارکرد مدار:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                const SizedBox(height: 4),
                Text(howItWorks, style: const TextStyle(fontSize: 12, height: 1.5)),
                const Divider(height: 18),
                const Text('تحلیل بلوک‌ها و سیم‌کشی:',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                const SizedBox(height: 4),
                ...blockDetails.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(d, style: const TextStyle(fontSize: 11)),
                    )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('بستن'),
          ),
        ],
      ),
    );
  }

  void _showPowerAndPanelBom() {
    final outputs = blocks.where((b) => b.type == BlockType.output).toList();
    const double plcBaseWatts = 3.5;
    double totalMaxWatts = plcBaseWatts;
    double activeNowWatts = plcBaseWatts;
    bool hasMotor = outputs.any(
      (q) => q.equipmentType == EquipmentType.motor || q.equipmentType == EquipmentType.pump,
    );

    for (final q in outputs) {
      totalMaxWatts += q.powerWatts;
      if (!isSimulating || q.value) {
        activeNowWatts += q.powerWatts;
      }
    }

    final double maxCurrent = totalMaxWatts / 220.0;
    final double activeCurrent = activeNowWatts / 220.0;

    // Auto-select MCB, Contactor, Bimetal, Wire Cross-Section
    String mcbRating = '6 A';
    String contactor = '9 A (LC1D09)';
    String bimetal = '1 - 1.6 A';
    String wireSize = '1.5 mm²';

    if (maxCurrent > 25) {
      mcbRating = '32 A';
      contactor = '32 A (LC1D32)';
      bimetal = '23 - 32 A';
      wireSize = '6 mm²';
    } else if (maxCurrent > 16) {
      mcbRating = '25 A';
      contactor = '25 A (LC1D25)';
      bimetal = '17 - 25 A';
      wireSize = '4 mm²';
    } else if (maxCurrent > 10) {
      mcbRating = '16 A';
      contactor = '18 A (LC1D18)';
      bimetal = '12 - 18 A';
      wireSize = '2.5 mm²';
    } else if (maxCurrent > 6) {
      mcbRating = '10 A';
      contactor = '12 A (LC1D12)';
      bimetal = '7 - 10 A';
      wireSize = '1.5 mm²';
    } else if (maxCurrent > 2) {
      mcbRating = '6 A';
      contactor = '9 A (LC1D09)';
      bimetal = '2.5 - 4 A';
      wireSize = '1.5 mm²';
    }

    final mcbCurve = hasMotor ? 'تیپ C (موتوری)' : 'تیپ B (روشنایی)';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('مصرف برق و تجهیزات تابلو برق'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('توان فعلی: ${activeNowWatts.toStringAsFixed(0)} W | حداکثر: ${totalMaxWatts.toStringAsFixed(0)} W',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
              Text('جریان فعلی: ${activeCurrent.toStringAsFixed(2)} A | جریان نامی کل: ${maxCurrent.toStringAsFixed(2)} A'),
              const Divider(),
              const Text('تجهیزات پیشنهادی تابلو برق:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
              const SizedBox(height: 4),
              Text('• کلید مینیاتوری (MCB): $mcbRating — $mcbCurve'),
              Text('• کنتاکتور پیشنهادی: $contactor'),
              if (hasMotor) Text('• رله حرارتی (بیمتال): $bimetal'),
              Text('• سطح مقطع سیم قدرت: $wireSize'),
              const Divider(),
              const Text('مصرف هر خروجی:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...outputs.map((q) => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${q.blockCode} (${q.label})'),
                      Text('${q.powerWatts.toInt()} W'),
                    ],
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('بستن'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportSnapshotAndReport() async {
    Uint8List? pngBytes;
    try {
      final boundary = _canvasRepaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 1.5);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        pngBytes = byteData?.buffer.asUint8List();
      }
    } catch (_) {}

    final sb = StringBuffer();
    sb.writeln('=== گزارش نقشه PLC - نرم‌افزار MOHSEN ===');
    sb.writeln('تعداد بلوک‌ها: ${blocks.length} | تعداد اتصالات: ${wires.length}');
    for (final b in blocks) {
      sb.writeln('- ${b.blockCode} [${b.type.shortName}] : ${b.label}');
    }
    sb.writeln('--- اتصالات ---');
    for (final w in wires) {
      final f = blocks.firstWhere((e) => e.id == w.fromBlockId, orElse: () => blocks.first);
      final t = blocks.firstWhere((e) => e.id == w.toBlockId, orElse: () => blocks.first);
      sb.writeln('${f.blockCode} --> ${t.blockCode} (Pin ${w.toPinIndex + 1})');
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('خروجی تصویر نقشه و گزارش کارگاهی'),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (pngBytes != null)
                  Container(
                    height: 180,
                    decoration: BoxDecoration(border: Border.all(color: Colors.black26)),
                    child: Image.memory(pngBytes, fit: BoxFit.contain),
                  ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.grey.shade100,
                  child: SelectableText(
                    sb.toString(),
                    style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: sb.toString()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('گزارش متنی کپی شد!')),
              );
            },
            child: const Text('کپی گزارش'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('بستن'),
          ),
        ],
      ),
    );
  }

  void _checkCircuitDiagnostics() {
    final issues = <String>[];
    for (final q in blocks.where((b) => b.type == BlockType.output)) {
      if (!wires.any((w) => w.toBlockId == q.id)) {
        issues.add('• خروجی ${q.blockCode} (${q.label}) به هیچ مداری وصل نیست!');
      }
    }
    final rsCount = blocks.where((b) => b.type == BlockType.rs).length;
    final notCount = blocks.where((b) => b.type == BlockType.notGate).length;
    if (rsCount >= 2 && notCount == 0) {
      issues.add('• هشدار عیب‌یابی: دو رله RS دارید ولی گیت NOT برای اینترلاک حفاظتی دیده نشد (خطر هم‌زمانی چپ‌گرد/راست‌گرد).');
    }
    if (blocks.isEmpty) {
      issues.add('• صفحه نقشه خالی است.');
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('نتیجه عیب‌یابی خودکار مدار'),
        content: Text(
          issues.isEmpty
              ? 'مدار سالم است و هیچ خطای سیم‌کشی یا اتصال بازی پیدا نشد.'
              : issues.join('\n'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('باشه'),
          ),
        ],
      ),
    );
  }

  void _showTruthTable() {
    final inputs = blocks.where((b) => b.type == BlockType.input).toList();
    final outputs = blocks.where((b) => b.type == BlockType.output).toList();

    if (inputs.isEmpty || outputs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حداقل یک ورودی (I) و یک خروجی (Q) لازم است.')),
      );
      return;
    }

    final evalInputs = inputs.take(5).toList();
    final int rowsCount = 1 << evalInputs.length;

    bool evalBlock(String id, Map<String, bool> inpState, int depth) {
      if (depth > 15) return false;
      final b = blocks.firstWhere((e) => e.id == id);
      if (b.type == BlockType.input) return inpState[b.id] ?? false;
      if (b.type == BlockType.high) return true;
      if (b.type == BlockType.low) return false;

      bool getIn(int pin) {
        final w = wires.where((e) => e.toBlockId == b.id && e.toPinIndex == pin);
        if (w.isEmpty) return false;
        return evalBlock(w.first.fromBlockId, inpState, depth + 1);
      }

      List<bool> connIns() {
        final res = <bool>[];
        for (int i = 0; i < b.type.inputCount; i++) {
          if (wires.any((e) => e.toBlockId == b.id && e.toPinIndex == i)) {
            res.add(getIn(i));
          }
        }
        return res;
      }

      switch (b.type) {
        case BlockType.output:
        case BlockType.flag:
        case BlockType.ton:
        case BlockType.tof:
        case BlockType.tp:
        case BlockType.stairway:
          return getIn(0);
        case BlockType.notGate:
          return !getIn(0);
        case BlockType.andGate:
        case BlockType.andEdge:
          final ins = connIns();
          return ins.isNotEmpty && ins.every((v) => v);
        case BlockType.orGate:
          return connIns().any((v) => v);
        case BlockType.nandGate:
          final ins = connIns();
          return !(ins.isNotEmpty && ins.every((v) => v));
        case BlockType.norGate:
          return !connIns().any((v) => v);
        case BlockType.xorGate:
          return getIn(0) != getIn(1);
        case BlockType.rs:
          final s = getIn(0);
          final r = getIn(1);
          if (r) return false;
          return s;
        default:
          return getIn(0);
      }
    }

    final List<List<bool>> tableRows = [];
    for (int r = 0; r < rowsCount; r++) {
      final inpState = <String, bool>{};
      final row = <bool>[];
      for (int c = 0; c < evalInputs.length; c++) {
        final bit = ((r >> (evalInputs.length - 1 - c)) & 1) == 1;
        inpState[evalInputs[c].id] = bit;
        row.add(bit);
      }
      for (final out in outputs) {
        row.add(evalBlock(out.id, inpState, 0));
      }
      tableRows.add(row);
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('جدول ارزشی مدار (Truth Table)'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(const Color(0xFF00695C)),
                columnSpacing: 16,
                columns: [
                  ...evalInputs.map((i) => DataColumn(
                        label: Text(i.label,
                            style: const TextStyle(
                                color: Colors.amberAccent,
                                fontWeight: FontWeight.bold)),
                      )),
                  ...outputs.map((o) => DataColumn(
                        label: Text(o.label,
                            style: const TextStyle(
                                color: Colors.lightGreenAccent,
                                fontWeight: FontWeight.bold)),
                      )),
                ],
                rows: tableRows.map((row) {
                  return DataRow(
                    cells: row.asMap().entries.map((entry) {
                      final isOut = entry.key >= evalInputs.length;
                      final val = entry.value;
                      return DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: val
                                ? (isOut
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.blue.withOpacity(0.15))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            val ? '1' : '0',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: val
                                  ? (isOut
                                      ? Colors.green.shade800
                                      : Colors.blue.shade800)
                                  : Colors.black54,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('بستن'),
          ),
        ],
      ),
    );
  }

  List<LadRung> _convertFbdToLadder() {
    final Map<String, PlcBlock> blockMap = {for (var b in blocks) b.id: b};

    LadNode? buildNode(String blockId, {bool invert = false, int depth = 0}) {
      if (depth > 10) return null;
      final b = blockMap[blockId];
      if (b == null) return null;

      List<String> incomingIds() {
        final res = <String>[];
        for (int i = 0; i < b.type.inputCount; i++) {
          final w = wires.where(
            (wire) => wire.toBlockId == b.id && wire.toPinIndex == i,
          );
          if (w.isNotEmpty) res.add(w.first.fromBlockId);
        }
        return res;
      }

      switch (b.type) {
        case BlockType.notGate:
          final ins = incomingIds();
          if (ins.isEmpty) return LadContact(b.id, b.label, inverted: !invert);
          return buildNode(ins.first, invert: !invert, depth: depth + 1);
        case BlockType.andGate:
        case BlockType.andEdge:
          final ins = incomingIds();
          if (ins.isEmpty) return null;
          if (invert) {
            return LadParallel(ins
                .map((id) => buildNode(id, invert: true, depth: depth + 1))
                .whereType<LadNode>()
                .toList());
          }
          return LadSeries(ins
              .map((id) => buildNode(id, invert: false, depth: depth + 1))
              .whereType<LadNode>()
              .toList());
        case BlockType.nandGate:
          final ins = incomingIds();
          if (ins.isEmpty) return null;
          if (!invert) {
            return LadParallel(ins
                .map((id) => buildNode(id, invert: true, depth: depth + 1))
                .whereType<LadNode>()
                .toList());
          }
          return LadSeries(ins
              .map((id) => buildNode(id, invert: false, depth: depth + 1))
              .whereType<LadNode>()
              .toList());
        case BlockType.orGate:
          final ins = incomingIds();
          if (ins.isEmpty) return null;
          if (invert) {
            return LadSeries(ins
                .map((id) => buildNode(id, invert: true, depth: depth + 1))
                .whereType<LadNode>()
                .toList());
          }
          return LadParallel(ins
              .map((id) => buildNode(id, invert: false, depth: depth + 1))
              .whereType<LadNode>()
              .toList());
        case BlockType.norGate:
          final ins = incomingIds();
          if (ins.isEmpty) return null;
          if (!invert) {
            return LadSeries(ins
                .map((id) => buildNode(id, invert: true, depth: depth + 1))
                .whereType<LadNode>()
                .toList());
          }
          return LadParallel(ins
              .map((id) => buildNode(id, invert: false, depth: depth + 1))
              .whereType<LadNode>()
              .toList());
        case BlockType.xorGate:
          final ins = incomingIds();
          if (ins.length < 2) return LadContact(b.id, b.label, inverted: invert);
          final a1 = buildNode(ins[0], invert: false, depth: depth + 1);
          final b1 = buildNode(ins[1], invert: true, depth: depth + 1);
          final a2 = buildNode(ins[0], invert: true, depth: depth + 1);
          final b2 = buildNode(ins[1], invert: false, depth: depth + 1);
          if (a1 != null && b1 != null && a2 != null && b2 != null) {
            return LadParallel([
              LadSeries([a1, b1]),
              LadSeries([a2, b2]),
            ]);
          }
          return LadContact(b.id, b.label, inverted: invert);
        default:
          return LadContact(b.id, b.label, inverted: invert);
      }
    }

    final rungs = <LadRung>[];
    for (final b in blocks) {
      if (b.type == BlockType.output ||
          b.type == BlockType.flag ||
          b.type == BlockType.messageText ||
          b.type.category == BlockCategory.sfTimer ||
          b.type.category == BlockCategory.sfCounter ||
          b.type == BlockType.rs ||
          b.type == BlockType.impulse) {
        if (b.type == BlockType.weeklyTimer || b.type == BlockType.yearlyTimer) {
          continue;
        }
        final w0 = wires.where((w) => w.toBlockId == b.id && w.toPinIndex == 0);
        LadNode? cond0 = w0.isNotEmpty ? buildNode(w0.first.fromBlockId) : null;

        if (b.type == BlockType.rs ||
            b.type == BlockType.impulse ||
            b.type == BlockType.tonr ||
            b.type == BlockType.ctud) {
          final rstPin = (b.type == BlockType.ctud) ? 2 : 1;
          final wRst = wires.where((w) => w.toBlockId == b.id && w.toPinIndex == rstPin);
          rungs.add(LadRung(
            coilLabel: '${b.blockCode} (S/${b.label})',
            targetBlock: b,
            condition: cond0,
          ));
          if (wRst.isNotEmpty) {
            rungs.add(LadRung(
              coilLabel: '${b.blockCode} (R)',
              targetBlock: b,
              condition: buildNode(wRst.first.fromBlockId),
            ));
          }
        } else {
          rungs.add(LadRung(
            coilLabel: '${b.blockCode} (${b.label})',
            targetBlock: b,
            condition: cond0,
          ));
        }
      }
    }
    return rungs;
  }

  void _addBlock(BlockType type) {
    if (isSimulating) return;
    setState(() {
      int count = blocks.where((b) => b.type == type).length + 1;
      String code = 'B${(blocks.length + 1).toString().padLeft(3, '0')}';
      String label = '${type.shortName}$count';
      if (type == BlockType.input) {
        code = 'I$count';
        label = 'I$count';
      } else if (type == BlockType.output) {
        code = 'Q$count';
        label = 'Q$count';
      } else if (type == BlockType.flag) {
        code = 'M$count';
        label = 'M$count';
      } else if (type == BlockType.analogInput) {
        code = 'AI$count';
        label = 'AI$count';
      }

      blocks.add(
        PlcBlock(
          id: _nextId('b'),
          blockCode: code,
          type: type,
          label: label,
          x: 80.0 + (blocks.length % 5) * 30.0,
          y: 60.0 + (blocks.length % 4) * 30.0,
          param: type == BlockType.ctud
              ? 5.0
              : (type == BlockType.analogCmp
                  ? 6.0
                  : (type == BlockType.weeklyTimer ? 18.0 : 3.0)),
          param2: type == BlockType.analogCmp
              ? 4.0
              : (type == BlockType.weeklyTimer ? 6.0 : 2.0),
          analogVal: type == BlockType.analogInput ? 5.0 : 0.0,
        ),
      );
    });
  }

  void _handlePinTap(String blockId, bool isOutput, int pinIndex) {
    if (isSimulating) return;
    setState(() {
      if (isOutput) {
        selectedOutputBlockId =
            (selectedOutputBlockId == blockId) ? null : blockId;
      } else if (selectedOutputBlockId != null &&
          selectedOutputBlockId != blockId) {
        wires.removeWhere(
          (w) => w.toBlockId == blockId && w.toPinIndex == pinIndex,
        );
        wires.add(
          PlcWire(
            id: _nextId('w'),
            fromBlockId: selectedOutputBlockId!,
            toBlockId: blockId,
            toPinIndex: pinIndex,
          ),
        );
        selectedOutputBlockId = null;
      } else {
        wires.removeWhere(
          (w) => w.toBlockId == blockId && w.toPinIndex == pinIndex,
        );
      }
    });
  }

  void _openBlockSettings(PlcBlock block) {
    if (isSimulating) return;
    final labelCtrl = TextEditingController(text: block.label);
    final paramCtrl = TextEditingController(text: block.param.toStringAsFixed(1));
    final param2Ctrl = TextEditingController(text: block.param2.toStringAsFixed(1));
    final msgCtrl = TextEditingController(text: block.messageText);
    final wattCtrl = TextEditingController(text: block.powerWatts.toStringAsFixed(0));
    bool isToggle = block.isToggle;
    EquipmentType eqType = block.equipmentType;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text('Properties: ${block.blockCode}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelCtrl,
                  decoration: const InputDecoration(
                    labelText: 'نام / برچسب',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: paramCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'پارامتر اول (زمان / PV / آستانه)',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (block.type == BlockType.output) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: wattCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'توان مصرفی خروجی (وات)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<EquipmentType>(
                    value: eqType,
                    decoration: const InputDecoration(
                      labelText: 'نوع تجهیز در نمای کارگاهی',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: EquipmentType.lamp, child: Text('لامپ / روشنایی')),
                      DropdownMenuItem(value: EquipmentType.motor, child: Text('موتور سه‌فاز')),
                      DropdownMenuItem(value: EquipmentType.pump, child: Text('پمپ و مخزن آب')),
                      DropdownMenuItem(value: EquipmentType.gate, child: Text('درب پارکینگ / جک')),
                    ],
                    onChanged: (v) {
                      if (v != null) setDlgState(() => eqType = v);
                    },
                  ),
                ],
                if (block.type == BlockType.messageText) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: msgCtrl,
                    decoration: const InputDecoration(
                      labelText: 'متن نمایشگر LCD',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                if (block.type == BlockType.input) ...[
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('کلید دائم (Switch)'),
                    value: isToggle,
                    onChanged: (v) => setDlgState(() => isToggle = v),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  wires.removeWhere(
                    (w) => w.fromBlockId == block.id || w.toBlockId == block.id,
                  );
                  blocks.removeWhere((b) => b.id == block.id);
                });
                Navigator.pop(ctx);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (labelCtrl.text.trim().isNotEmpty) {
                    block.label = labelCtrl.text.trim();
                  }
                  final parsed = double.tryParse(paramCtrl.text.trim());
                  if (parsed != null && parsed >= 0) block.param = parsed;
                  final parsed2 = double.tryParse(param2Ctrl.text.trim());
                  if (parsed2 != null && parsed2 >= 0) block.param2 = parsed2;
                  final w = double.tryParse(wattCtrl.text.trim());
                  if (w != null && w >= 0) block.powerWatts = w;
                  if (msgCtrl.text.trim().isNotEmpty) {
                    block.messageText = msgCtrl.text.trim();
                  }
                  block.isToggle = isToggle;
                  block.equipmentType = eqType;
                });
                Navigator.pop(ctx);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  void _loadTemplate(String name) {
    if (isSimulating) _toggleSimulation();
    setState(() {
      blocks.clear();
      wires.clear();
      selectedOutputBlockId = null;
      _idCounter = 1;

      switch (name) {
        case 'p1_multi_switch':
          blocks = [
            PlcBlock(id: 'b1', blockCode: 'I1', type: BlockType.input, label: 'شستی موازی', x: 30, y: 30, isToggle: false),
            PlcBlock(id: 'b8', blockCode: 'B008', type: BlockType.ton, label: 'سه شستی', x: 160, y: 80, param: 5.0),
            PlcBlock(id: 'b4', blockCode: 'B004', type: BlockType.stairway, label: 'همکف', x: 380, y: 30, param: 15.0),
            PlcBlock(id: 'q1', blockCode: 'Q1', type: BlockType.output, label: 'راهرو همکف', x: 520, y: 30, powerWatts: 200, equipmentType: EquipmentType.lamp),

            PlcBlock(id: 'b2', blockCode: 'I2', type: BlockType.input, label: 'راه‌پله', x: 30, y: 185, isToggle: false),
            PlcBlock(id: 'b01', blockCode: 'B001', type: BlockType.orGate, label: 'OR', x: 270, y: 180),
            PlcBlock(id: 'b9', blockCode: 'B009', type: BlockType.stairway, label: 'تایمر پله', x: 400, y: 180, param: 15.0),
            PlcBlock(id: 'q2', blockCode: 'Q2', type: BlockType.output, label: 'لامپ راه‌پله', x: 540, y: 180, powerWatts: 250, equipmentType: EquipmentType.lamp),

            PlcBlock(id: 'b3', blockCode: 'I3', type: BlockType.input, label: 'پاگرد', x: 30, y: 320, isToggle: false),
            PlcBlock(id: 'b02', blockCode: 'B002', type: BlockType.orGate, label: 'OR', x: 270, y: 315),
            PlcBlock(id: 'b6', blockCode: 'B006', type: BlockType.stairway, label: 'تایمر پاگرد', x: 400, y: 315, param: 15.0),
            PlcBlock(id: 'q3', blockCode: 'Q3', type: BlockType.output, label: 'لامپ پاگرد', x: 540, y: 315, powerWatts: 250, equipmentType: EquipmentType.lamp),

            PlcBlock(id: 'b4i', blockCode: 'I4', type: BlockType.input, label: 'طبقه ۱', x: 30, y: 455, isToggle: false),
            PlcBlock(id: 'b03', blockCode: 'B003', type: BlockType.orGate, label: 'OR', x: 270, y: 450),
            PlcBlock(id: 'b5', blockCode: 'B005', type: BlockType.stairway, label: 'طبقه اول', x: 400, y: 450, param: 15.0),
            PlcBlock(id: 'q4', blockCode: 'Q4', type: BlockType.output, label: 'راهرو طبقه ۱', x: 540, y: 450, powerWatts: 200, equipmentType: EquipmentType.lamp),
          ];
          wires = [
            PlcWire(id: 'w1', fromBlockId: 'b1', toBlockId: 'b4', toPinIndex: 0),
            PlcWire(id: 'w2', fromBlockId: 'b4', toBlockId: 'q1', toPinIndex: 0),
            PlcWire(id: 'w3', fromBlockId: 'b1', toBlockId: 'b8', toPinIndex: 0),
            PlcWire(id: 'w4', fromBlockId: 'b8', toBlockId: 'b01', toPinIndex: 0),
            PlcWire(id: 'w5', fromBlockId: 'b2', toBlockId: 'b01', toPinIndex: 1),
            PlcWire(id: 'w6', fromBlockId: 'b01', toBlockId: 'b9', toPinIndex: 0),
            PlcWire(id: 'w7', fromBlockId: 'b9', toBlockId: 'q2', toPinIndex: 0),
            PlcWire(id: 'w8', fromBlockId: 'b8', toBlockId: 'b02', toPinIndex: 0),
            PlcWire(id: 'w9', fromBlockId: 'b3', toBlockId: 'b02', toPinIndex: 1),
            PlcWire(id: 'w10', fromBlockId: 'b02', toBlockId: 'b6', toPinIndex: 0),
            PlcWire(id: 'w11', fromBlockId: 'b6', toBlockId: 'q3', toPinIndex: 0),
            PlcWire(id: 'w12', fromBlockId: 'b8', toBlockId: 'b03', toPinIndex: 0),
            PlcWire(id: 'w13', fromBlockId: 'b4i', toBlockId: 'b03', toPinIndex: 1),
            PlcWire(id: 'w14', fromBlockId: 'b03', toBlockId: 'b5', toPinIndex: 0),
            PlcWire(id: 'w15', fromBlockId: 'b5', toBlockId: 'q4', toPinIndex: 0),
          ];
          break;
        case 'p2_stardelta':
          blocks = [
            PlcBlock(id: 'b1', blockCode: 'I1', type: BlockType.input, label: 'Start', x: 40, y: 40, isToggle: false),
            PlcBlock(id: 'b2', blockCode: 'I2', type: BlockType.input, label: 'Stop', x: 40, y: 140, isToggle: false),
            PlcBlock(id: 'b3', blockCode: 'B001', type: BlockType.rs, label: 'RS', x: 160, y: 80),
            PlcBlock(id: 'b4', blockCode: 'B002', type: BlockType.ton, label: 'T1', x: 160, y: 185, param: 4.0),
            PlcBlock(id: 'b5', blockCode: 'B003', type: BlockType.notGate, label: 'NOT', x: 280, y: 145),
            PlcBlock(id: 'b6', blockCode: 'B004', type: BlockType.andGate, label: 'AND', x: 400, y: 125),
            PlcBlock(id: 'b7', blockCode: 'Q1', type: BlockType.output, label: 'Main', x: 400, y: 20, powerWatts: 2200, equipmentType: EquipmentType.motor),
            PlcBlock(id: 'b8', blockCode: 'Q2', type: BlockType.output, label: 'Star', x: 520, y: 125, powerWatts: 1100, equipmentType: EquipmentType.motor),
            PlcBlock(id: 'b9', blockCode: 'Q3', type: BlockType.output, label: 'Delta', x: 520, y: 220, powerWatts: 2200, equipmentType: EquipmentType.motor),
          ];
          wires = [
            PlcWire(id: 'w1', fromBlockId: 'b1', toBlockId: 'b3', toPinIndex: 0),
            PlcWire(id: 'w2', fromBlockId: 'b2', toBlockId: 'b3', toPinIndex: 1),
            PlcWire(id: 'w3', fromBlockId: 'b3', toBlockId: 'b7', toPinIndex: 0),
            PlcWire(id: 'w4', fromBlockId: 'b3', toBlockId: 'b4', toPinIndex: 0),
            PlcWire(id: 'w5', fromBlockId: 'b4', toBlockId: 'b5', toPinIndex: 0),
            PlcWire(id: 'w6', fromBlockId: 'b3', toBlockId: 'b6', toPinIndex: 0),
            PlcWire(id: 'w7', fromBlockId: 'b5', toBlockId: 'b6', toPinIndex: 1),
            PlcWire(id: 'w8', fromBlockId: 'b6', toBlockId: 'b8', toPinIndex: 0),
            PlcWire(id: 'w9', fromBlockId: 'b4', toBlockId: 'b9', toPinIndex: 0),
          ];
          break;
        case 'p3_pump':
          blocks = [
            PlcBlock(id: 'b1', blockCode: 'I1', type: BlockType.input, label: 'کف', x: 40, y: 50),
            PlcBlock(id: 'b2', blockCode: 'I2', type: BlockType.input, label: 'سقف', x: 40, y: 160),
            PlcBlock(id: 'b3', blockCode: 'B001', type: BlockType.notGate, label: 'NOT', x: 170, y: 50),
            PlcBlock(id: 'b4', blockCode: 'B002', type: BlockType.rs, label: 'RS', x: 300, y: 100),
            PlcBlock(id: 'b5', blockCode: 'Q1', type: BlockType.output, label: 'پمپ آب', x: 440, y: 100, powerWatts: 1500, equipmentType: EquipmentType.pump),
          ];
          wires = [
            PlcWire(id: 'w1', fromBlockId: 'b1', toBlockId: 'b3', toPinIndex: 0),
            PlcWire(id: 'w2', fromBlockId: 'b3', toBlockId: 'b4', toPinIndex: 0),
            PlcWire(id: 'w3', fromBlockId: 'b2', toBlockId: 'b4', toPinIndex: 1),
            PlcWire(id: 'w4', fromBlockId: 'b4', toBlockId: 'b5', toPinIndex: 0),
          ];
          break;
        case 'fault_rev':
          // Intentional Fault Circuit: Missing Interlock!
          blocks = [
            PlcBlock(id: 'b1', blockCode: 'I1', type: BlockType.input, label: 'راست', x: 40, y: 40, isToggle: false),
            PlcBlock(id: 'b2', blockCode: 'I2', type: BlockType.input, label: 'چپ', x: 40, y: 160, isToggle: false),
            PlcBlock(id: 'b3', blockCode: 'I3', type: BlockType.input, label: 'Stop', x: 40, y: 270, isToggle: false),
            PlcBlock(id: 'b4', blockCode: 'B001', type: BlockType.rs, label: 'RS_R', x: 220, y: 50),
            PlcBlock(id: 'b5', blockCode: 'B002', type: BlockType.rs, label: 'RS_L', x: 220, y: 170),
            PlcBlock(id: 'q1', blockCode: 'Q1', type: BlockType.output, label: 'راست‌گرد', x: 400, y: 50, powerWatts: 1500, equipmentType: EquipmentType.motor),
            PlcBlock(id: 'q2', blockCode: 'Q2', type: BlockType.output, label: 'چپ‌گرد', x: 400, y: 170, powerWatts: 1500, equipmentType: EquipmentType.motor),
          ];
          wires = [
            PlcWire(id: 'w1', fromBlockId: 'b1', toBlockId: 'b4', toPinIndex: 0),
            PlcWire(id: 'w2', fromBlockId: 'b3', toBlockId: 'b4', toPinIndex: 1),
            PlcWire(id: 'w3', fromBlockId: 'b4', toBlockId: 'q1', toPinIndex: 0),
            PlcWire(id: 'w4', fromBlockId: 'b2', toBlockId: 'b5', toPinIndex: 0),
            PlcWire(id: 'w5', fromBlockId: 'b3', toBlockId: 'b5', toPinIndex: 1),
            PlcWire(id: 'w6', fromBlockId: 'b5', toBlockId: 'q2', toPinIndex: 0),
          ];
          break;
        case 'p5_retentive':
          blocks = [
            PlcBlock(id: 'b1', blockCode: 'I1', type: BlockType.input, label: 'شروع', x: 40, y: 50),
            PlcBlock(id: 'b2', blockCode: 'I2', type: BlockType.input, label: 'ریست', x: 40, y: 160, isToggle: false),
            PlcBlock(id: 'b3', blockCode: 'B001', type: BlockType.tonr, label: 'TONR', x: 200, y: 100, param: 8.0),
            PlcBlock(id: 'q1', blockCode: 'Q1', type: BlockType.output, label: 'آلارم', x: 360, y: 100, powerWatts: 100, equipmentType: EquipmentType.lamp),
          ];
          wires = [
            PlcWire(id: 'w1', fromBlockId: 'b1', toBlockId: 'b3', toPinIndex: 0),
            PlcWire(id: 'w2', fromBlockId: 'b2', toBlockId: 'b3', toPinIndex: 1),
            PlcWire(id: 'w3', fromBlockId: 'b3', toBlockId: 'q1', toPinIndex: 0),
          ];
          break;
      }
      _idCounter = blocks.length + wires.length + 10;
    });
  }

  void _showJsonDialog() {
    final jsonStr = jsonEncode({
      'blocks': blocks.map((b) => b.toJson()).toList(),
      'wires': wires.map((w) => w.toJson()).toList(),
    });
    final ctrl = TextEditingController(text: jsonStr);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save / Load Project (JSON)'),
        content: TextField(
          controller: ctrl,
          maxLines: 5,
          style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: ctrl.text));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied!')),
              );
            },
            child: const Text('Copy'),
          ),
          ElevatedButton(
            onPressed: () {
              try {
                final data = jsonDecode(ctrl.text);
                if (isSimulating) _toggleSimulation();
                setState(() {
                  blocks = (data['blocks'] as List)
                      .map((e) => PlcBlock.fromJson(e))
                      .toList();
                  wires = (data['wires'] as List)
                      .map((e) => PlcWire.fromJson(e))
                      .toList();
                });
                Navigator.pop(ctx);
              } catch (_) {}
            },
            child: const Text('Load'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inputs = blocks.where((b) => b.type == BlockType.input).toList();
    final analogInputs =
        blocks.where((b) => b.type == BlockType.analogInput).toList();
    final hasWeekly = blocks.any(
      (b) => b.type == BlockType.weeklyTimer || b.type == BlockType.yearlyTimer,
    );
    final outputs = blocks.where((b) => b.type == BlockType.output).toList();
    final activeMsg = isSimulating
        ? blocks.where((b) => b.type == BlockType.messageText && b.value).toList()
        : <PlcBlock>[];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // --- Classic Desktop LOGO! Soft Comfort Menu & Toolbar ---
            Container(
              height: 38,
              color: const Color(0xFFE0E4E8),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text(
                      'MOHSEN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF004D40),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28),
                      icon: Icon(
                        showTreeSidebar ? Icons.menu_open : Icons.menu,
                        size: 18,
                        color: Colors.black87,
                      ),
                      onPressed: () =>
                          setState(() => showTreeSidebar = !showTreeSidebar),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'مدارها و تمرین‌ها',
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 5),
                        child: Text('مدارها ▾',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87)),
                      ),
                      onSelected: (val) {
                        if (val == 'clear') {
                          if (isSimulating) _toggleSimulation();
                          setState(() {
                            blocks.clear();
                            wires.clear();
                          });
                        } else if (val == 'json') {
                          _showJsonDialog();
                        } else if (val == 'diag') {
                          _checkCircuitDiagnostics();
                        } else {
                          _loadTemplate(val);
                        }
                      },
                      itemBuilder: (ctx) => const [
                        PopupMenuItem(value: 'p1_multi_switch', child: Text('شکل ۲۸: مدار شستی چندکاره (کتاب)')),
                        PopupMenuItem(value: 'p2_stardelta', child: Text('پودمان ۲: ستاره-مثلث خودکار')),
                        PopupMenuItem(value: 'p3_pump', child: Text('پودمان ۳: پمپ و مخزن آب')),
                        PopupMenuItem(value: 'p5_retentive', child: Text('پودمان ۵: تایمر ماندگار (تست قطع برق)')),
                        PopupMenuDivider(),
                        PopupMenuItem(value: 'fault_rev', child: Text('تمرین عیب‌یابی: چپ‌گرد/راست‌گرد معیوب!')),
                        PopupMenuItem(value: 'diag', child: Text('بررسی خودکار خطای مدار')),
                        PopupMenuDivider(),
                        PopupMenuItem(value: 'json', child: Text('ذخیره / ورود JSON')),
                        PopupMenuItem(value: 'clear', child: Text('پاک کردن صفحه (مدار خالی)')),
                      ],
                    ),
                    const SizedBox(width: 4),
                    _topToolBtn(
                      label: viewMode == 0
                          ? 'FBD'
                          : (viewMode == 1
                              ? 'LAD'
                              : (viewMode == 2
                                  ? 'SCOPE'
                                  : (viewMode == 3 ? 'کارگاه' : 'سخت‌افزار'))),
                      icon: Icons.layers,
                      color: Colors.indigo,
                      onTap: () => setState(() => viewMode = (viewMode + 1) % 5),
                    ),
                    const SizedBox(width: 4),
                    _topToolBtn(
                      label: isCanvasLocked ? 'صفحه: قفل' : 'قفل صفحه',
                      icon: isCanvasLocked ? Icons.lock : Icons.lock_open,
                      color: isCanvasLocked ? Colors.red.shade700 : Colors.grey.shade700,
                      onTap: () => setState(() => isCanvasLocked = !isCanvasLocked),
                    ),
                    const SizedBox(width: 4),
                    _topToolBtn(
                      label: isWireTool ? 'سیم‌کشی: فعال' : 'سیم‌کشی دستی',
                      icon: Icons.cable,
                      color: isWireTool ? Colors.deepOrange : Colors.blueGrey.shade700,
                      onTap: () => setState(() {
                        isWireTool = !isWireTool;
                        selectedOutputBlockId = null;
                      }),
                    ),
                    const SizedBox(width: 4),
                    _topToolBtn(
                      label: 'فرمول بولی',
                      icon: Icons.functions,
                      color: Colors.pink.shade700,
                      onTap: _openBooleanDialog,
                    ),
                    const SizedBox(width: 4),
                    _topToolBtn(
                      label: 'ماشین‌حساب',
                      icon: Icons.calculate,
                      color: Colors.green.shade800,
                      onTap: _openElectricalCalculatorDialog,
                    ),
                    const SizedBox(width: 4),
                    _topToolBtn(
                      label: 'پروژه‌ها',
                      icon: Icons.save,
                      color: Colors.brown.shade600,
                      onTap: _openLocalProjectsDialog,
                    ),
                    const SizedBox(width: 4),
                    _topToolBtn(
                      label: 'قطعات الکترونیک',
                      icon: Icons.memory,
                      color: Colors.cyan.shade800,
                      onTap: _openComponentEncyclopediaDialog,
                    ),
                    const SizedBox(width: 4),
                    _topToolBtn(
                      label: 'توضیح مدار',
                      icon: Icons.info_outline,
                      color: Colors.deepPurple.shade600,
                      onTap: _explainCurrentCircuit,
                    ),
                    const SizedBox(width: 4),
                    _topToolBtn(
                      label: 'هوش مصنوعی API',
                      icon: Icons.psychology,
                      color: Colors.deepPurple.shade800,
                      onTap: _openAiApiDialog,
                    ),
                    const SizedBox(width: 4),
                    _topToolBtn(
                      label: 'کد آردوینو/میکرو',
                      icon: Icons.code,
                      color: Colors.teal.shade900,
                      onTap: _openArduinoCodeExportDialog,
                    ),
                    const SizedBox(width: 4),
                    _topToolBtn(
                      label: 'دستیار مدار',
                      icon: Icons.auto_awesome,
                      color: Colors.purple.shade700,
                      onTap: _openCircuitAssistantDialog,
                    ),
                    const SizedBox(width: 4),
                    _topToolBtn(
                      label: 'مصرف/تابلو',
                      icon: Icons.bolt,
                      color: Colors.amber.shade800,
                      onTap: _showPowerAndPanelBom,
                    ),
                    const SizedBox(width: 4),
                    _topToolBtn(
                      label: 'جدول ارزشی',
                      icon: Icons.table_chart,
                      color: Colors.teal.shade800,
                      onTap: _showTruthTable,
                    ),
                    const SizedBox(width: 4),
                    _topToolBtn(
                      label: 'ارسال به هاست',
                      icon: Icons.cloud_upload,
                      color: Colors.blue.shade800,
                      onTap: _openHostShareDialog,
                    ),
                    const SizedBox(width: 4),
                    _topToolBtn(
                      label: 'خروجی/چاپ',
                      icon: Icons.camera_alt,
                      color: Colors.brown.shade700,
                      onTap: _exportSnapshotAndReport,
                    ),
                    const SizedBox(width: 4),
                    _topToolBtn(
                      label: isSimulating ? 'STOP' : 'SIM (F3)',
                      icon: isSimulating ? Icons.stop : Icons.play_arrow,
                      color: isSimulating ? Colors.red : Colors.green.shade700,
                      onTap: _toggleSimulation,
                    ),
                  ],
                ),
              ),
            ),
            // --- Multi-Page Sheet Tabs (+ صفحه خالی جدید) ---
            Container(
              height: 28,
              color: const Color(0xFFCFD8DC),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (int i = 0; i < pagesBlocks.length; i++)
                    GestureDetector(
                      onTap: () => _switchPage(i),
                      child: Container(
                        margin: const EdgeInsets.only(right: 4, top: 3),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: i == currentPage
                              ? Colors.white
                              : const Color(0xFFB0BEC5),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                          border: Border.all(color: Colors.black26),
                        ),
                        child: Row(
                          children: [
                            Text(
                              pageNames[i],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: i == currentPage
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: Colors.black87,
                              ),
                            ),
                            if (pagesBlocks.length > 1) ...[
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => _closePage(i),
                                child: const Icon(Icons.close,
                                    size: 12, color: Colors.black54),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  InkWell(
                    onTap: _addNewBlankPage,
                    child: Container(
                      margin: const EdgeInsets.only(top: 3, bottom: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00796B),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Center(
                        child: Text(
                          '+ صفحه خالی جدید',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isPowerOutage && isSimulating)
              Container(
                width: double.infinity,
                color: Colors.red.shade900,
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: const Text(
                  '⚡ وضعیت قطع برق (Power Failure) — تایمرهای ماندگار (TONR) و شمارنده‌ها مقدار خود را حفظ می‌کنند',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            if (activeMsg.isNotEmpty)
              Container(
                width: double.infinity,
                color: const Color(0xFFFFB300),
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(
                  'LOGO! LCD: ${activeMsg.first.messageText}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontFamily: 'monospace'),
                ),
              ),
            Expanded(
              child: Row(
                children: [
                  if (showTreeSidebar && !isSimulating && viewMode == 0)
                    Container(
                      width: 150,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        border: Border(right: BorderSide(color: Color(0xFFCBD5E1))),
                      ),
                      child: ListView(
                        padding: const EdgeInsets.all(4),
                        children: [
                          _treeGroup('▼ Co (I/Q/M)', BlockCategory.co),
                          _treeGroup('▼ GF (Logic)', BlockCategory.gf),
                          _treeGroup('▼ SF (Timers)', BlockCategory.sfTimer),
                          _treeGroup('▼ SF (Counters)', BlockCategory.sfCounter),
                          _treeGroup('▼ SF (Analog)', BlockCategory.sfAnalog),
                          _treeGroup('▼ SF (Misc)', BlockCategory.sfMisc),
                        ],
                      ),
                    ),
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      child: viewMode == 0
                          ? _buildFbdCanvas()
                          : (viewMode == 1
                              ? _buildLadderView()
                              : (viewMode == 2
                                  ? _buildScopeView()
                                  : (viewMode == 3
                                      ? _buildPlantWorkshopView(outputs)
                                      : _buildHardwareLogoView()))),
                    ),
                  ),
                ],
              ),
            ),
            if (isSimulating)
              _buildSimIoBar(inputs, analogInputs, hasWeekly, outputs),
          ],
        ),
      ),
    );
  }

  Widget _topToolBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: Colors.white),
            const SizedBox(width: 3),
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _treeGroup(String title, BlockCategory cat) {
    final items = BlockType.values.where((b) => b.category == cat).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 2),
          child: Text(
            title,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00695C)),
          ),
        ),
        ...items.map((t) {
          return InkWell(
            onTap: () => _addBlock(t),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: t.logoBodyColor.withOpacity(0.55),
                border: Border.all(color: Colors.black12),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                '${t.shortName}  ${t.title}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: Colors.black87),
              ),
            ),
          );
        }),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildFbdCanvas() {
    return RepaintBoundary(
      key: _canvasRepaintKey,
      child: InteractiveViewer(
        constrained: false,
        panEnabled: !isCanvasLocked && !isWireTool,
        scaleEnabled: !isCanvasLocked && !isWireTool,
        boundaryMargin: const EdgeInsets.all(400),
        minScale: 0.4,
        maxScale: 2.0,
        child: SizedBox(
          width: 1400,
          height: 1000,
          child: Stack(
            children: [
              CustomPaint(
                size: const Size(1400, 1000),
                painter: _CheckeredGridAndWirePainter(
                  blocks: blocks,
                  wires: wires,
                  blockWidth: blockWidth,
                  blockHeight: blockHeight,
                  isSimulating: isSimulating,
                  dragStart: dragWireStart,
                  dragEnd: dragWireCurrent,
                ),
              ),
              ...blocks.map((b) => _buildBlockWidget(b)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlantWorkshopView(List<PlcBlock> outputs) {
    if (outputs.isEmpty) {
      return const Center(
        child: Text('هیچ خروجی (Q) در مدار برای نمایش تجهیزات کارگاهی وجود ندارد.'),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: outputs.length,
      itemBuilder: (_, i) {
        final q = outputs[i];
        final on = isSimulating && q.value;
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: on ? const Color(0xFFE8F5E9) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: on ? Colors.green : Colors.black26,
              width: on ? 2.2 : 1.0,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${q.blockCode}: ${q.label}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 8),
              if (q.equipmentType == EquipmentType.motor)
                RotationTransition(
                  turns: on ? _motorAnim : const AlwaysStoppedAnimation(0),
                  child: Icon(
                    Icons.settings,
                    size: 46,
                    color: on ? Colors.green.shade700 : Colors.grey,
                  ),
                )
              else if (q.equipmentType == EquipmentType.lamp)
                Icon(
                  Icons.lightbulb,
                  size: 46,
                  color: on ? Colors.amber.shade700 : Colors.grey.shade400,
                )
              else if (q.equipmentType == EquipmentType.pump)
                Column(
                  children: [
                    Icon(Icons.water_drop,
                        size: 26, color: on ? Colors.blue : Colors.grey),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 90,
                      child: LinearProgressIndicator(
                        value: tankLevels[q.id] ?? 0.3,
                        minHeight: 12,
                        backgroundColor: Colors.grey.shade300,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    Icon(Icons.sensor_door,
                        size: 30, color: on ? Colors.orange : Colors.grey),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 90,
                      child: LinearProgressIndicator(
                        value: gatePositions[q.id] ?? 0.0,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade300,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 6),
              Text(
                on ? 'روشن / در حال کار' : 'خاموش',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: on ? Colors.green.shade800 : Colors.black45,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScopeView() {
    if (scopeHistory.isEmpty) {
      return const Center(
        child: Text(
          'ابتدا SIM (F3) را بزنید تا نمودار زمانی سیگنال‌ها رسم شود.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }
    final keys = scopeHistory.last.keys.toList();
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: keys.length,
      itemBuilder: (_, idx) {
        final label = keys[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF151C26),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent)),
              const SizedBox(height: 4),
              SizedBox(
                height: 26,
                width: double.infinity,
                child: CustomPaint(
                  painter: _ScopePainter(
                    samples: scopeHistory.map((m) => m[label] ?? false).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLadderView() {
    final rungs = _convertFbdToLadder();
    final blockMap = {for (var b in blocks) b.id: b};

    if (rungs.isEmpty) {
      return const Center(
        child: Text(
          'حداقل یک خروجی (Q) یا تایمر در مدار قرار دهید.',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(400),
      minScale: 0.35,
      maxScale: 2.5,
      child: SizedBox(
        width: 1400,
        height: math.max(800.0, rungs.length * 160.0 + 120.0),
        child: CustomPaint(
          size: Size(1400, math.max(800.0, rungs.length * 160.0 + 120.0)),
          painter: _UnifiedLadderPainter(
            rungs: rungs,
            blockMap: blockMap,
            isSimulating: isSimulating,
          ),
        ),
      ),
    );
  }

  Widget _buildBlockWidget(PlcBlock block) {
    final isSelectedOut = selectedOutputBlockId == block.id;
    final inCount = block.type.inputCount;
    final pinLabels = block.type.pinLabels;
    final bool hasParamBox = block.type.category == BlockCategory.sfTimer ||
        block.type.category == BlockCategory.sfCounter;

    return Positioned(
      left: block.x,
      top: block.y,
      child: GestureDetector(
        onPanUpdate: (isSimulating || isWireTool)
            ? null
            : (details) {
                setState(() {
                  block.x = (block.x + details.delta.dx).clamp(0, 1280);
                  block.y = (block.y + details.delta.dy).clamp(0, 900);
                });
              },
        onTap: () {
          if (isSimulating && block.type == BlockType.input && block.isToggle) {
            setState(() => block.value = !block.value);
          }
        },
        onLongPress: () => _openBlockSettings(block),
        onDoubleTap: () => _openBlockSettings(block),
        child: SizedBox(
          width: blockWidth + 28,
          height: blockHeight + (hasParamBox ? 48 : 16),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 14,
                top: 0,
                child: SizedBox(
                  width: blockWidth,
                  child: Text(
                    '${block.blockCode} (${block.label})',
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                top: 14,
                child: Container(
                  width: blockWidth,
                  height: blockHeight,
                  decoration: BoxDecoration(
                    color: block.type.logoBodyColor,
                    border: Border.all(
                      color: (isSimulating && block.value)
                          ? Colors.red
                          : (isSelectedOut ? Colors.deepOrange : Colors.black87),
                      width: (isSimulating && block.value) || isSelectedOut
                          ? 2.0
                          : 1.2,
                    ),
                  ),
                  child: CustomPaint(
                    painter: _BlockSymbolPainter(type: block.type),
                  ),
                ),
              ),
              // Hanging Parameter Table Box (Ta / T) exactly like Textbook Figure 28!
              if (hasParamBox)
                Positioned(
                  left: 10,
                  top: 14 + blockHeight + 2,
                  child: Container(
                    width: blockWidth + 8,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      border: Border.all(color: Colors.black54, width: 0.9),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Ta:', style: TextStyle(fontSize: 8, color: Colors.black87)),
                            Text(
                              block.type == BlockType.ctud
                                  ? '${block.elapsed.toInt()}'
                                  : '${block.elapsed.toStringAsFixed(1)}s',
                              style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(block.type == BlockType.ctud ? 'PV:' : 'T:',
                                style: const TextStyle(fontSize: 8, color: Colors.black87)),
                            Text(
                              block.type == BlockType.ctud
                                  ? '${block.param.toInt()}'
                                  : '${block.param.toStringAsFixed(1)}s',
                              style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              for (int i = 0; i < inCount; i++)
                Positioned(
                  left: 0,
                  top: 14 + _pinY(i, inCount) - 11,
                  child: GestureDetector(
                    onTap: () => _handlePinTap(block.id, false, i),
                    child: Container(
                      width: 24,
                      height: 22,
                      alignment: Alignment.center,
                      child: Container(
                        width: 14,
                        height: 12,
                        decoration: BoxDecoration(
                          color: selectedOutputBlockId != null
                              ? Colors.amber
                              : Colors.white,
                          border: Border.all(color: Colors.black87, width: 1.2),
                        ),
                        child: Center(
                          child: Text(
                            pinLabels[i].substring(0, 1),
                            style: const TextStyle(
                              fontSize: 7,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              if (block.type.hasOutput)
                Positioned(
                  right: 0,
                  top: 14 + (blockHeight / 2) - 11,
                  child: GestureDetector(
                    onTap: () => _handlePinTap(block.id, true, 0),
                    onPanStart: (!isSimulating && isWireTool)
                        ? (_) {
                            setState(() {
                              dragFromBlockId = block.id;
                              dragWireStart = Offset(
                                block.x + 14 + blockWidth + 5,
                                block.y + 14 + (blockHeight / 2),
                              );
                              dragWireCurrent = dragWireStart;
                            });
                          }
                        : null,
                    onPanUpdate: (!isSimulating && isWireTool)
                        ? (d) {
                            setState(() {
                              if (dragWireCurrent != null) {
                                dragWireCurrent = dragWireCurrent! + d.delta;
                              }
                            });
                          }
                        : null,
                    onPanEnd: (!isSimulating && isWireTool)
                        ? (_) {
                            if (dragFromBlockId != null && dragWireCurrent != null) {
                              for (final tb in blocks) {
                                if (tb.id == dragFromBlockId) continue;
                                for (int i = 0; i < tb.type.inputCount; i++) {
                                  final pinPos = Offset(
                                    tb.x + 14 - 5,
                                    tb.y + 14 + _pinY(i, tb.type.inputCount),
                                  );
                                  if ((pinPos - dragWireCurrent!).distance < 28) {
                                    setState(() {
                                      wires.removeWhere((w) =>
                                          w.toBlockId == tb.id && w.toPinIndex == i);
                                      wires.add(PlcWire(
                                        id: _nextId('w'),
                                        fromBlockId: dragFromBlockId!,
                                        toBlockId: tb.id,
                                        toPinIndex: i,
                                      ));
                                    });
                                    break;
                                  }
                                }
                              }
                            }
                            setState(() {
                              dragFromBlockId = null;
                              dragWireStart = null;
                              dragWireCurrent = null;
                            });
                          }
                        : null,
                    child: Container(
                      width: 24,
                      height: 22,
                      alignment: Alignment.center,
                      child: Container(
                        width: 13,
                        height: 13,
                        decoration: BoxDecoration(
                          color: isSelectedOut
                              ? Colors.deepOrange
                              : (isSimulating && block.value
                                  ? Colors.red
                                  : const Color(0xFF00838F)),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black87, width: 1.2),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  double _pinY(int index, int total) {
    if (total == 1) return blockHeight / 2;
    const topPad = 14.0;
    final usable = blockHeight - topPad - 10.0;
    return topPad + (usable / (total - 1)) * index;
  }

  Widget _buildSimIoBar(
    List<PlcBlock> inputs,
    List<PlcBlock> analogInputs,
    bool hasWeekly,
    List<PlcBlock> outputs,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: const Color(0xFF1E293B),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            InkWell(
              onTap: () => setState(() => vibrateOnOutput = !vibrateOnOutput),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: vibrateOnOutput ? Colors.purple : Colors.blueGrey.shade700,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  vibrateOnOutput ? 'ویبره: روشن' : 'ویبره: خاموش',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            // Power Failure Simulation Button
            InkWell(
              onTap: _togglePowerOutage,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: isPowerOutage ? Colors.red : Colors.orange.shade800,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  isPowerOutage ? 'وصل برق ⚡' : 'قطع برق ⚡',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ),
            if (hasWeekly) ...[
              Text(
                'ساعت: ${simHour.toInt()}:00',
                style: const TextStyle(fontSize: 11, color: Colors.amberAccent),
              ),
              SizedBox(
                width: 100,
                child: Slider(
                  value: simHour,
                  min: 0.0,
                  max: 23.0,
                  divisions: 23,
                  onChanged: (v) => setState(() => simHour = v),
                ),
              ),
            ],
            if (analogInputs.isNotEmpty)
              ...analogInputs.map((ai) => Row(
                    children: [
                      Text('${ai.label}: ${ai.analogVal.toStringAsFixed(1)}V',
                          style: const TextStyle(
                              fontSize: 11, color: Colors.cyanAccent)),
                      SizedBox(
                        width: 100,
                        child: Slider(
                          value: ai.analogVal,
                          min: 0.0,
                          max: 10.0,
                          divisions: 100,
                          onChanged: (v) => setState(() => ai.analogVal = v),
                        ),
                      ),
                    ],
                  )),
            ...inputs.map((inp) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTapDown: inp.isToggle
                      ? null
                      : (_) => setState(() => inp.value = true),
                  onTapUp: inp.isToggle
                      ? null
                      : (_) => setState(() => inp.value = false),
                  onTapCancel: inp.isToggle
                      ? null
                      : () => setState(() => inp.value = false),
                  onTap: inp.isToggle
                      ? () => setState(() => inp.value = !inp.value)
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: inp.value ? Colors.green : Colors.blueGrey.shade700,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(inp.label,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ),
              );
            }),
            const SizedBox(width: 10),
            ...outputs.map((out) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  children: [
                    Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: out.value ? Colors.amber : Colors.grey.shade700,
                        boxShadow: out.value
                            ? [const BoxShadow(color: Colors.amber, blurRadius: 6)]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(out.label,
                        style: const TextStyle(fontSize: 11, color: Colors.white)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _ScopePainter extends CustomPainter {
  final List<bool> samples;
  _ScopePainter({required this.samples});

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;
    final paint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final step = size.width / math.max(1, samples.length - 1);
    for (int i = 0; i < samples.length; i++) {
      final x = i * step;
      final y = samples[i] ? 4.0 : size.height - 4.0;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevY = samples[i - 1] ? 4.0 : size.height - 4.0;
        if (prevY != y) path.lineTo(x, prevY);
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ScopePainter oldDelegate) => true;
}

class _CheckeredGridAndWirePainter extends CustomPainter {
  final List<PlcBlock> blocks;
  final List<PlcWire> wires;
  final double blockWidth;
  final double blockHeight;
  final bool isSimulating;
  final Offset? dragStart;
  final Offset? dragEnd;

  _CheckeredGridAndWirePainter({
    required this.blocks,
    required this.wires,
    required this.blockWidth,
    required this.blockHeight,
    required this.isSimulating,
    this.dragStart,
    this.dragEnd,
  });

  double _pinY(int index, int total) {
    if (total == 1) return blockHeight / 2;
    const topPad = 14.0;
    final usable = blockHeight - topPad - 10.0;
    return topPad + (usable / (total - 1)) * index;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final minorPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 0.8;
    final majorPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.2;

    for (double x = 0; x <= size.width; x += 20) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        (x % 100 == 0) ? majorPaint : minorPaint,
      );
    }
    for (double y = 0; y <= size.height; y += 20) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        (y % 100 == 0) ? majorPaint : minorPaint,
      );
    }

    final blockMap = {for (var b in blocks) b.id: b};
    for (final w in wires) {
      final fromB = blockMap[w.fromBlockId];
      final toB = blockMap[w.toBlockId];
      if (fromB == null || toB == null) continue;

      final start = Offset(
        fromB.x + 14 + blockWidth + 5,
        fromB.y + 14 + (blockHeight / 2),
      );
      final end = Offset(
        toB.x + 14 - 5,
        toB.y + 14 + _pinY(w.toPinIndex, toB.type.inputCount),
      );

      final isHigh = isSimulating && fromB.value;
      final wirePaint = Paint()
        ..color = isHigh ? Colors.red : Colors.black87
        ..strokeWidth = isHigh ? 2.6 : 1.6
        ..style = PaintingStyle.stroke;

      final midX = (start.dx + end.dx) / 2;
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(midX, start.dy)
        ..lineTo(midX, end.dy)
        ..lineTo(end.dx, end.dy);
      canvas.drawPath(path, wirePaint);

      if (wires.where((x) => x.fromBlockId == w.fromBlockId).length > 1) {
        canvas.drawCircle(
          Offset(midX, start.dy),
          3.2,
          Paint()..color = isHigh ? Colors.red : Colors.black87,
        );
      }
    }

    if (dragStart != null && dragEnd != null) {
      final previewPaint = Paint()
        ..color = Colors.deepOrange
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(dragStart!, dragEnd!, previewPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CheckeredGridAndWirePainter oldDelegate) => true;
}


class _BlockSymbolPainter extends CustomPainter {
  final BlockType type;
  _BlockSymbolPainter({required this.type});

  void _drawLabel(Canvas canvas, Size size, String text, Offset center,
      {double fontSize = 15, bool bold = true}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.black87,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final p = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    switch (type) {
      case BlockType.ton:
      case BlockType.tonr:
        // Top wide pulse _|‾‾‾|_
        final top = Path()
          ..moveTo(w * 0.16, h * 0.36)
          ..lineTo(w * 0.28, h * 0.36)
          ..lineTo(w * 0.28, h * 0.16)
          ..lineTo(w * 0.72, h * 0.16)
          ..lineTo(w * 0.72, h * 0.36)
          ..lineTo(w * 0.84, h * 0.36);
        canvas.drawPath(top, p);
        // Bottom delayed pulse ___|‾|_
        final bot = Path()
          ..moveTo(w * 0.16, h * 0.68)
          ..lineTo(w * 0.48, h * 0.68)
          ..lineTo(w * 0.48, h * 0.48)
          ..lineTo(w * 0.72, h * 0.48)
          ..lineTo(w * 0.72, h * 0.68)
          ..lineTo(w * 0.84, h * 0.68);
        canvas.drawPath(bot, p);
        if (type == BlockType.tonr) {
          _drawLabel(canvas, size, 'R', Offset(w * 0.5, h * 0.85), fontSize: 10);
        }
        break;

      case BlockType.tof:
        // Top short pulse _|‾|___
        final top = Path()
          ..moveTo(w * 0.16, h * 0.36)
          ..lineTo(w * 0.28, h * 0.36)
          ..lineTo(w * 0.28, h * 0.16)
          ..lineTo(w * 0.48, h * 0.16)
          ..lineTo(w * 0.48, h * 0.36)
          ..lineTo(w * 0.84, h * 0.36);
        canvas.drawPath(top, p);
        // Bottom extended pulse _|‾‾‾|_
        final bot = Path()
          ..moveTo(w * 0.16, h * 0.68)
          ..lineTo(w * 0.28, h * 0.68)
          ..lineTo(w * 0.28, h * 0.48)
          ..lineTo(w * 0.72, h * 0.48)
          ..lineTo(w * 0.72, h * 0.68)
          ..lineTo(w * 0.84, h * 0.68);
        canvas.drawPath(bot, p);
        break;

      case BlockType.tp:
        // Wiping relay: narrow fixed pulse
        final top = Path()
          ..moveTo(w * 0.16, h * 0.36)
          ..lineTo(w * 0.28, h * 0.36)
          ..lineTo(w * 0.28, h * 0.16)
          ..lineTo(w * 0.74, h * 0.16)
          ..lineTo(w * 0.74, h * 0.36)
          ..lineTo(w * 0.84, h * 0.36);
        canvas.drawPath(top, p);
        final bot = Path()
          ..moveTo(w * 0.16, h * 0.68)
          ..lineTo(w * 0.28, h * 0.68)
          ..lineTo(w * 0.28, h * 0.48)
          ..lineTo(w * 0.50, h * 0.48)
          ..lineTo(w * 0.50, h * 0.68)
          ..lineTo(w * 0.84, h * 0.68);
        canvas.drawPath(bot, p);
        break;

      case BlockType.pulse:
        // Async Pulse square wave _|‾|_|‾|_
        final wave = Path()
          ..moveTo(w * 0.15, h * 0.62)
          ..lineTo(w * 0.25, h * 0.62)
          ..lineTo(w * 0.25, h * 0.34)
          ..lineTo(w * 0.43, h * 0.34)
          ..lineTo(w * 0.43, h * 0.62)
          ..lineTo(w * 0.60, h * 0.62)
          ..lineTo(w * 0.60, h * 0.34)
          ..lineTo(w * 0.78, h * 0.34)
          ..lineTo(w * 0.78, h * 0.62)
          ..lineTo(w * 0.86, h * 0.62);
        canvas.drawPath(wave, p);
        break;

      case BlockType.impulse:
      case BlockType.stairway:
        // Two top pulses _|‾|_|‾|_
        final top = Path()
          ..moveTo(w * 0.14, h * 0.32)
          ..lineTo(w * 0.24, h * 0.32)
          ..lineTo(w * 0.24, h * 0.14)
          ..lineTo(w * 0.40, h * 0.14)
          ..lineTo(w * 0.40, h * 0.32)
          ..lineTo(w * 0.58, h * 0.32)
          ..lineTo(w * 0.58, h * 0.14)
          ..lineTo(w * 0.74, h * 0.14)
          ..lineTo(w * 0.74, h * 0.32)
          ..lineTo(w * 0.86, h * 0.32);
        canvas.drawPath(top, p);
        // Bottom toggle/stairway pulse _|‾‾‾|_
        final bot = Path()
          ..moveTo(w * 0.14, h * 0.62)
          ..lineTo(w * 0.28, h * 0.62)
          ..lineTo(w * 0.28, h * 0.44)
          ..lineTo(w * 0.70, h * 0.44)
          ..lineTo(w * 0.70, h * 0.62)
          ..lineTo(w * 0.86, h * 0.62);
        canvas.drawPath(bot, p);
        _drawLabel(
          canvas,
          size,
          type == BlockType.impulse ? 'RS' : 'T',
          Offset(w * 0.5, h * 0.82),
          fontSize: 10,
        );
        break;

      default:
        _drawLabel(canvas, size, type.shortName, Offset(w * 0.5, h * 0.5),
            fontSize: 17);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _BlockSymbolPainter oldDelegate) =>
      oldDelegate.type != type;
}

class _UnifiedLadderPainter extends CustomPainter {
  final List<LadRung> rungs;
  final Map<String, PlcBlock> blockMap;
  final bool isSimulating;

  _UnifiedLadderPainter({
    required this.rungs,
    required this.blockMap,
    required this.isSimulating,
  });

  double _nodeWidth(LadNode node) {
    if (node is LadContact) return 78.0;
    if (node is LadSeries) {
      double w = 0;
      for (final c in node.items) {
        w += _nodeWidth(c);
      }
      return math.max(78.0, w);
    }
    if (node is LadParallel) {
      double maxW = 78.0;
      for (final b in node.branches) {
        maxW = math.max(maxW, _nodeWidth(b));
      }
      return maxW + 32.0;
    }
    return 78.0;
  }

  double _nodeHeight(LadNode node) {
    if (node is LadContact) return 46.0;
    if (node is LadSeries) {
      double maxH = 46.0;
      for (final c in node.items) {
        maxH = math.max(maxH, _nodeHeight(c));
      }
      return maxH;
    }
    if (node is LadParallel) {
      double h = 0;
      for (final b in node.branches) {
        h += _nodeHeight(b);
      }
      return math.max(46.0, h);
    }
    return 46.0;
  }

  void _drawText(Canvas canvas, String text, Offset center, Color color,
      {double fontSize = 9, bool bold = true}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  void _paintNode(Canvas canvas, LadNode node, double x, double y,
      double width, bool incomingPower) {
    final active = incomingPower && node.isActive(blockMap);
    final linePaint = Paint()
      ..color = incomingPower ? Colors.red : Colors.black87
      ..strokeWidth = incomingPower ? 2.2 : 1.5
      ..style = PaintingStyle.stroke;
    final outPaint = Paint()
      ..color = active ? Colors.red : Colors.black87
      ..strokeWidth = active ? 2.2 : 1.5
      ..style = PaintingStyle.stroke;

    if (node is LadContact) {
      final midX = x + width / 2;
      canvas.drawLine(Offset(x, y), Offset(midX - 8, y), linePaint);
      final barPaint = Paint()
        ..color = active ? Colors.red : Colors.black87
        ..strokeWidth = 2.0;
      canvas.drawLine(Offset(midX - 8, y - 10), Offset(midX - 8, y + 10), barPaint);
      canvas.drawLine(Offset(midX + 8, y - 10), Offset(midX + 8, y + 10), barPaint);
      if (node.inverted) {
        canvas.drawLine(Offset(midX - 8, y + 10), Offset(midX + 8, y - 10), barPaint);
      }
      canvas.drawLine(Offset(midX + 8, y), Offset(x + width, y), outPaint);
      _drawText(canvas, node.label, Offset(midX, y - 18),
          active ? Colors.red.shade800 : Colors.black87,
          fontSize: 9);
    } else if (node is LadSeries) {
      double curX = x;
      bool curPower = incomingPower;
      for (final child in node.items) {
        final cw = _nodeWidth(child);
        _paintNode(canvas, child, curX, y, cw, curPower);
        curPower = curPower && child.isActive(blockMap);
        curX += cw;
      }
      if (curX < x + width) {
        canvas.drawLine(Offset(curX, y), Offset(x + width, y), outPaint);
      }
    } else if (node is LadParallel) {
      final branchX = x + 16;
      final branchW = width - 32;
      final List<double> branchYs = [];
      double offsetY = y;
      for (int i = 0; i < node.branches.length; i++) {
        final bh = _nodeHeight(node.branches[i]);
        if (i == 0) {
          branchYs.add(y);
          offsetY = y + bh;
        } else {
          branchYs.add(offsetY);
          offsetY += bh;
        }
      }
      canvas.drawLine(Offset(x, y), Offset(branchX, y), linePaint);
      canvas.drawLine(Offset(branchX, branchYs.first),
          Offset(branchX, branchYs.last), linePaint);

      final rightMergeX = branchX + branchW;
      for (int i = 0; i < node.branches.length; i++) {
        final br = node.branches[i];
        final by = branchYs[i];
        final bw = _nodeWidth(br);
        _paintNode(canvas, br, branchX, by, bw, incomingPower);
        final brActive = incomingPower && br.isActive(blockMap);
        final brPaint = Paint()
          ..color = brActive ? Colors.red : Colors.black87
          ..strokeWidth = brActive ? 2.2 : 1.5;
        if (branchX + bw < rightMergeX) {
          canvas.drawLine(Offset(branchX + bw, by), Offset(rightMergeX, by), brPaint);
        }
      }
      canvas.drawLine(Offset(rightMergeX, branchYs.first),
          Offset(rightMergeX, branchYs.last), outPaint);
      canvas.drawLine(Offset(rightMergeX, y), Offset(x + width, y), outPaint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final minorPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 0.8;
    final majorPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.2;

    for (double x = 0; x <= size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height),
          (x % 100 == 0) ? majorPaint : minorPaint);
    }
    for (double y = 0; y <= size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y),
          (y % 100 == 0) ? majorPaint : minorPaint);
    }

    const double leftRailX = 40.0;
    double maxCondW = 360.0;
    double curY = 60.0;
    double totalH = curY;

    for (final r in rungs) {
      if (r.condition != null) {
        maxCondW = math.max(maxCondW, _nodeWidth(r.condition!));
      }
      final h = r.condition != null ? _nodeHeight(r.condition!) : 46.0;
      totalH += math.max(70.0, h + 30.0);
    }

    final double rightRailX = leftRailX + 40.0 + maxCondW + 140.0;
    final railPaint = Paint()
      ..color = isSimulating ? Colors.red : Colors.black87
      ..strokeWidth = 2.4;
    final rightRailPaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2.4;

    canvas.drawLine(Offset(leftRailX, 30), Offset(leftRailX, totalH), railPaint);
    canvas.drawLine(Offset(rightRailX, 30), Offset(rightRailX, totalH), rightRailPaint);

    for (final rung in rungs) {
      final rungH = rung.condition != null ? _nodeHeight(rung.condition!) : 46.0;
      final isPowered =
          isSimulating && (rung.condition?.isActive(blockMap) ?? false);
      final wirePaint = Paint()
        ..color = isPowered ? Colors.red : Colors.black87
        ..strokeWidth = isPowered ? 2.2 : 1.5;

      double endX = leftRailX + 30;
      canvas.drawLine(Offset(leftRailX, curY), Offset(endX, curY), railPaint);

      if (rung.condition != null) {
        final nw = _nodeWidth(rung.condition!);
        _paintNode(canvas, rung.condition!, endX, curY, nw, isSimulating);
        endX += nw;
      }

      final coilCenterX = rightRailX - 75;
      if (endX < coilCenterX - 16) {
        canvas.drawLine(
            Offset(endX, curY), Offset(coilCenterX - 16, curY), wirePaint);
      }

      final coilPaint = Paint()
        ..color = (isSimulating && rung.targetBlock.value)
            ? Colors.red
            : Colors.black87
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      canvas.drawArc(
        Rect.fromCenter(center: Offset(coilCenterX - 6, curY), width: 16, height: 24),
        2.1,
        2.1,
        false,
        coilPaint,
      );
      canvas.drawArc(
        Rect.fromCenter(center: Offset(coilCenterX + 6, curY), width: 16, height: 24),
        -1.05,
        2.1,
        false,
        coilPaint,
      );

      _drawText(
        canvas,
        rung.coilLabel,
        Offset(coilCenterX, curY - 20),
        (isSimulating && rung.targetBlock.value) ? Colors.red.shade800 : Colors.black87,
        fontSize: 9,
      );

      canvas.drawLine(
          Offset(coilCenterX + 14, curY), Offset(rightRailX, curY), wirePaint);

      curY += math.max(70.0, rungH + 30.0);
    }
  }

  @override
  bool shouldRepaint(covariant _UnifiedLadderPainter oldDelegate) => true;
}
