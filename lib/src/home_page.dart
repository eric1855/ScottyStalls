import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/restroom.dart';
import 'reader_review_page.dart';
import 'package:provider/provider.dart';
import 'providers/restroom_provider.dart';
import 'providers/location_provider.dart';
import 'building_map_page.dart';

// ---------------------------------------------------------------------------
// Actual building footprints from OpenStreetMap
// ---------------------------------------------------------------------------

final Map<String, List<LatLng>> kBuildingPolygons = {
  'Tepper School of Business': [
    LatLng(40.4455943, -79.9445439), LatLng(40.4455919, -79.9446134),
    LatLng(40.4455858, -79.9447895), LatLng(40.4455808, -79.9449341),
    LatLng(40.4455733, -79.9451528), LatLng(40.4455703, -79.9452661),
    LatLng(40.4452289, -79.9454988), LatLng(40.4449722, -79.9456631),
    LatLng(40.4449605, -79.9461284), LatLng(40.4449508, -79.9461288),
    LatLng(40.4448417, -79.9461241), LatLng(40.4448395, -79.9461834),
    LatLng(40.4447507, -79.9461941), LatLng(40.4447533, -79.9461149),
    LatLng(40.4446865, -79.9461105), LatLng(40.4446665, -79.9458272),
    LatLng(40.4447153, -79.9457097), LatLng(40.4446978, -79.9456849),
    LatLng(40.4446737, -79.9456506), LatLng(40.4447303, -79.9455068),
    LatLng(40.4447466, -79.9450589), LatLng(40.4450047, -79.9448825),
    LatLng(40.445039, -79.9448591), LatLng(40.4451084, -79.9450321),
    LatLng(40.4452219, -79.944953), LatLng(40.4453325, -79.9448758),
    LatLng(40.4453381, -79.9447203), LatLng(40.4454623, -79.9446348),
  ],
  'Cohon University Center': [
    LatLng(40.4430272, -79.9427601), LatLng(40.4430146, -79.942701),
    LatLng(40.4429809, -79.9425463), LatLng(40.4429778, -79.9425015),
    LatLng(40.4431868, -79.9424212), LatLng(40.4431772, -79.9423761),
    LatLng(40.4431894, -79.9423404), LatLng(40.4431811, -79.9423013),
    LatLng(40.4431506, -79.942292), LatLng(40.4431458, -79.9422714),
    LatLng(40.4431722, -79.9422601), LatLng(40.443165, -79.9422274),
    LatLng(40.4431493, -79.942204), LatLng(40.443137, -79.9422008),
    LatLng(40.4431303, -79.9421685), LatLng(40.443127, -79.9421525),
    LatLng(40.4429153, -79.9422326), LatLng(40.4427693, -79.9415823),
    LatLng(40.4430372, -79.9414842), LatLng(40.4430541, -79.9415503),
    LatLng(40.4431696, -79.9415078), LatLng(40.4431597, -79.9414658),
    LatLng(40.4431956, -79.9413891), LatLng(40.443229, -79.9413829),
    LatLng(40.4432563, -79.941398), LatLng(40.4432761, -79.9414358),
    LatLng(40.4432774, -79.9414753), LatLng(40.4432649, -79.9414974),
    LatLng(40.44327, -79.9415181), LatLng(40.4434477, -79.9414525),
    LatLng(40.4436321, -79.9413846), LatLng(40.4437058, -79.9417179),
    LatLng(40.4437181, -79.9417729), LatLng(40.4439604, -79.941677),
    LatLng(40.4439488, -79.9416246), LatLng(40.4439211, -79.9414947),
    LatLng(40.4441505, -79.9414055), LatLng(40.444225, -79.9417401),
    LatLng(40.4441774, -79.9417555), LatLng(40.4441847, -79.941788),
    LatLng(40.4440648, -79.9418349), LatLng(40.4441163, -79.9420587),
    LatLng(40.4441266, -79.9420783), LatLng(40.4441818, -79.9423213),
    LatLng(40.4441027, -79.9423518), LatLng(40.4440917, -79.9423007),
    LatLng(40.4437566, -79.9424263), LatLng(40.4433886, -79.9425665),
    LatLng(40.4430932, -79.9426791), LatLng(40.4431034, -79.9427294),
  ],
  'Gates and Hillman Centers': [
    LatLng(40.4430765, -79.9444932), LatLng(40.4431005, -79.9445566),
    LatLng(40.4431423, -79.9446564), LatLng(40.4431574, -79.944694),
    LatLng(40.4430785, -79.9447237), LatLng(40.4431074, -79.9447888),
    LatLng(40.4431333, -79.9448518), LatLng(40.4431689, -79.9448329),
    LatLng(40.4431839, -79.9449595), LatLng(40.4431996, -79.9451032),
    LatLng(40.4433289, -79.9450788), LatLng(40.4433421, -79.9452195),
    LatLng(40.4433695, -79.9452105), LatLng(40.4433471, -79.9449676),
    LatLng(40.4435295, -79.9448774), LatLng(40.4436593, -79.9448327),
    LatLng(40.4437004, -79.9448184), LatLng(40.443678, -79.9447186),
    LatLng(40.44372, -79.9447028), LatLng(40.4436634, -79.944426),
    LatLng(40.4437701, -79.9443713), LatLng(40.4438052, -79.9444927),
    LatLng(40.4438115, -79.9445155), LatLng(40.4438783, -79.9447427),
    LatLng(40.4440367, -79.9447382), LatLng(40.4440338, -79.9445593),
    LatLng(40.4440274, -79.9441672), LatLng(40.4439845, -79.9441681),
    LatLng(40.4439842, -79.9441482), LatLng(40.4439993, -79.9441454),
    LatLng(40.4439985, -79.9440819), LatLng(40.4437897, -79.9441299),
    LatLng(40.4437865, -79.9441061), LatLng(40.4436947, -79.9441244),
    LatLng(40.4437083, -79.9442305), LatLng(40.4437682, -79.9442166),
    LatLng(40.4437877, -79.9442845), LatLng(40.4437501, -79.9443045),
    LatLng(40.4437605, -79.9443396), LatLng(40.4436559, -79.9443929),
    LatLng(40.4436266, -79.9442565), LatLng(40.4436022, -79.9441455),
    LatLng(40.4434617, -79.9442868), LatLng(40.4434162, -79.9443339),
    LatLng(40.4433979, -79.9443404), LatLng(40.4432656, -79.9443875),
    LatLng(40.4432863, -79.9445632), LatLng(40.4432713, -79.9445738),
    LatLng(40.4432509, -79.9445877), LatLng(40.4431634, -79.9444251),
    LatLng(40.4431362, -79.9444463), LatLng(40.4431273, -79.9444533),
  ],
  'Newell-Simon Hall': [
    LatLng(40.4432213, -79.9460511), LatLng(40.4434227, -79.9459775),
    LatLng(40.4434149, -79.9459459), LatLng(40.4434689, -79.9459228),
    LatLng(40.4434901, -79.9460301), LatLng(40.443697, -79.9459493),
    LatLng(40.4436507, -79.9457261), LatLng(40.4436181, -79.9457375),
    LatLng(40.4435813, -79.9455568), LatLng(40.4435457, -79.9453919),
    LatLng(40.4435769, -79.9453765), LatLng(40.4435318, -79.9451555),
    LatLng(40.4433695, -79.9452105), LatLng(40.4433421, -79.9452195),
    LatLng(40.4430652, -79.9453222), LatLng(40.443132, -79.9456293),
    LatLng(40.4431439, -79.9456856),
  ],
  'Hamburg Hall': [
    LatLng(40.4444585, -79.9461698), LatLng(40.4438586, -79.9461405),
    LatLng(40.4438638, -79.9459549), LatLng(40.4440368, -79.9459633),
    LatLng(40.4441895, -79.9459708), LatLng(40.4441902, -79.9459477),
    LatLng(40.4441976, -79.9456868), LatLng(40.444159, -79.9456715),
    LatLng(40.4441319, -79.945645), LatLng(40.4441107, -79.9456016),
    LatLng(40.4441044, -79.9455486), LatLng(40.4441134, -79.9455011),
    LatLng(40.444132, -79.9454575), LatLng(40.4441629, -79.945428),
    LatLng(40.4442052, -79.9454152), LatLng(40.4442122, -79.9451708),
    LatLng(40.444213, -79.9451422), LatLng(40.4438918, -79.9451265),
    LatLng(40.4438975, -79.9449261), LatLng(40.4444928, -79.9449552),
    LatLng(40.4444873, -79.9451515), LatLng(40.4444056, -79.9451475),
    LatLng(40.4443938, -79.9455629), LatLng(40.4443826, -79.94596),
    LatLng(40.4443821, -79.9459761), LatLng(40.4444638, -79.94598),
  ],
  'Hunt Library': [
    LatLng(40.4413262, -79.9440246), LatLng(40.4410365, -79.9441294),
    LatLng(40.4408936, -79.9434563), LatLng(40.4411855, -79.9433505),
    LatLng(40.4412781, -79.9437898),
  ],
  'Purnell Center for the Arts': [
    LatLng(40.4432855, -79.9439564), LatLng(40.4438386, -79.9437511),
    LatLng(40.443764, -79.943401), LatLng(40.4438044, -79.9433848),
    LatLng(40.4438185, -79.9434477), LatLng(40.4439317, -79.9434121),
    LatLng(40.4439186, -79.9433473), LatLng(40.4439355, -79.9433415),
    LatLng(40.4439619, -79.9433336), LatLng(40.4439269, -79.9431679),
    LatLng(40.4439169, -79.9431234), LatLng(40.4438908, -79.9431325),
    LatLng(40.4432444, -79.9433631), LatLng(40.443233, -79.9433075),
    LatLng(40.4431541, -79.9433372), LatLng(40.4431724, -79.9434299),
    LatLng(40.4431801, -79.9434692), LatLng(40.4431354, -79.943505),
    LatLng(40.4431096, -79.943563), LatLng(40.4431025, -79.9436194),
    LatLng(40.4431071, -79.9436835), LatLng(40.4431269, -79.9437367),
    LatLng(40.4431713, -79.943779), LatLng(40.4432275, -79.9437945),
    LatLng(40.4432504, -79.9437871),
  ],
  'Warner Hall': [
    LatLng(40.4440147, -79.9433486), LatLng(40.4440523, -79.9435337),
    LatLng(40.4443393, -79.9434329), LatLng(40.4443017, -79.9432478),
    LatLng(40.4441601, -79.9432968),
  ],
  'Posner Hall': [
    LatLng(40.4416182, -79.9421926), LatLng(40.4415849, -79.9420249),
    LatLng(40.4415541, -79.9418622), LatLng(40.4409443, -79.9421211),
    LatLng(40.4409477, -79.9421368), LatLng(40.4409184, -79.9421479),
    LatLng(40.440933, -79.9422147), LatLng(40.4409792, -79.9424263),
    LatLng(40.4410896, -79.9423847), LatLng(40.4411215, -79.9423726),
    LatLng(40.4411231, -79.9423797), LatLng(40.4411433, -79.9423721),
  ],
  'College of Fine Arts': [
    LatLng(40.4412741, -79.9432583), LatLng(40.441622, -79.9431243),
    LatLng(40.4419556, -79.9430138), LatLng(40.4419101, -79.9427989),
    LatLng(40.4418626, -79.9425651), LatLng(40.4417154, -79.9426153),
    LatLng(40.4412292, -79.9427885), LatLng(40.4411782, -79.9428078),
  ],
  'Doherty Hall': [
    LatLng(40.4425295, -79.9450587), LatLng(40.4426211, -79.9450294),
    LatLng(40.4426255, -79.9450464), LatLng(40.4428733, -79.9449607),
    LatLng(40.4426898, -79.9440867), LatLng(40.4424882, -79.9441484),
    LatLng(40.4424457, -79.9441614), LatLng(40.4424298, -79.9440879),
    LatLng(40.4424732, -79.9440726), LatLng(40.4424614, -79.9440133),
    LatLng(40.4424306, -79.943868), LatLng(40.4423722, -79.9438872),
    LatLng(40.4423693, -79.9438735), LatLng(40.4422973, -79.943899),
    LatLng(40.4422311, -79.943923), LatLng(40.4422341, -79.9439378),
    LatLng(40.442174, -79.9439602), LatLng(40.4422174, -79.9441668),
    LatLng(40.4422287, -79.9441647), LatLng(40.4422755, -79.9443892),
    LatLng(40.4422998, -79.9443803), LatLng(40.4423089, -79.9444168),
    LatLng(40.4423111, -79.9444296), LatLng(40.4422852, -79.9444394),
    LatLng(40.442162, -79.9444839), LatLng(40.4422947, -79.9451229),
    LatLng(40.4423509, -79.9451036), LatLng(40.4424443, -79.9450714),
    LatLng(40.4424494, -79.9450917), LatLng(40.442469, -79.9450812),
  ],
  'Baker Hall': [
    LatLng(40.4417238, -79.9457236), LatLng(40.4418872, -79.9456653),
    LatLng(40.4418587, -79.9455259), LatLng(40.4418468, -79.9454766),
    LatLng(40.4417046, -79.9455304), LatLng(40.4416949, -79.9455028),
    LatLng(40.4417059, -79.9455005), LatLng(40.4416567, -79.945271),
    LatLng(40.4417934, -79.945221), LatLng(40.4417655, -79.9450864),
    LatLng(40.4417544, -79.9450334), LatLng(40.4416132, -79.9450883),
    LatLng(40.4415656, -79.9448315), LatLng(40.4417033, -79.944781),
    LatLng(40.4416727, -79.9446431), LatLng(40.4416611, -79.944591),
    LatLng(40.4415177, -79.9446422), LatLng(40.4414519, -79.9443592),
    LatLng(40.4415124, -79.944339), LatLng(40.4414709, -79.9441308),
    LatLng(40.4414058, -79.9441531), LatLng(40.4414014, -79.9441402),
    LatLng(40.4413193, -79.9441604), LatLng(40.4412694, -79.9441921),
    LatLng(40.4412708, -79.9442036), LatLng(40.441207, -79.9442267),
    LatLng(40.4412521, -79.94443), LatLng(40.4413154, -79.9444113),
    LatLng(40.4413295, -79.9444818), LatLng(40.4411353, -79.9445438),
    LatLng(40.4411821, -79.9447484), LatLng(40.4413523, -79.9446879),
    LatLng(40.4413901, -79.9449281), LatLng(40.4413948, -79.9449484),
    LatLng(40.4412373, -79.9450086), LatLng(40.4412828, -79.9451948),
    LatLng(40.4414538, -79.9451297), LatLng(40.4415073, -79.9453849),
    LatLng(40.4413343, -79.9454523), LatLng(40.4413667, -79.9456239),
    LatLng(40.4415478, -79.9455721), LatLng(40.4415831, -79.9457668),
    LatLng(40.4415885, -79.9457652), LatLng(40.4416002, -79.9457691),
  ],
  'Porter Hall': [
    LatLng(40.4417362, -79.9468052), LatLng(40.4415882, -79.9468574),
    LatLng(40.441493, -79.946402), LatLng(40.4415095, -79.9463967),
    LatLng(40.441502, -79.9463549), LatLng(40.4414939, -79.9463571),
    LatLng(40.4414802, -79.9463211), LatLng(40.4414493, -79.9461396),
    LatLng(40.4414382, -79.9461415), LatLng(40.4413884, -79.9459135),
    LatLng(40.4415341, -79.9458575), LatLng(40.4415813, -79.9460861),
    LatLng(40.441596, -79.9460806), LatLng(40.4415981, -79.9460879),
    LatLng(40.4416287, -79.9460778), LatLng(40.441586, -79.9458456),
    LatLng(40.4416122, -79.9458386), LatLng(40.4416002, -79.9457691),
    LatLng(40.4417238, -79.9457236), LatLng(40.4417348, -79.9457911),
    LatLng(40.4417689, -79.9457777), LatLng(40.4418215, -79.9460349),
    LatLng(40.4419842, -79.9459765), LatLng(40.442015, -79.9461094),
    LatLng(40.4420258, -79.9461635), LatLng(40.4420151, -79.9461682),
    LatLng(40.4420201, -79.9461944), LatLng(40.4420665, -79.9464265),
    LatLng(40.4419884, -79.9464454), LatLng(40.441874, -79.9464844),
    LatLng(40.4418749, -79.9464926), LatLng(40.4417901, -79.9465252),
    LatLng(40.4418032, -79.9465776), LatLng(40.4417784, -79.9465851),
    LatLng(40.4417969, -79.9466885), LatLng(40.4417451, -79.9467095),
    LatLng(40.44172, -79.9467184),
  ],
  'Wean Hall': [
    LatLng(40.4428409, -79.9465192), LatLng(40.4428358, -79.9464958),
    LatLng(40.4427968, -79.9463137), LatLng(40.4428303, -79.9463012),
    LatLng(40.4428449, -79.9463693), LatLng(40.4429186, -79.946342),
    LatLng(40.4428224, -79.9458934), LatLng(40.4428588, -79.94588),
    LatLng(40.4428405, -79.9457949), LatLng(40.4428368, -79.9457777),
    LatLng(40.4428284, -79.9457808), LatLng(40.4428238, -79.9457596),
    LatLng(40.4428218, -79.9457504), LatLng(40.4428661, -79.945734),
    LatLng(40.4428648, -79.9457282), LatLng(40.4427709, -79.9452911),
    LatLng(40.4428283, -79.9452698), LatLng(40.4428058, -79.945165),
    LatLng(40.4427559, -79.9451835), LatLng(40.4427309, -79.945067),
    LatLng(40.442546, -79.9451355), LatLng(40.4425295, -79.9450587),
    LatLng(40.442469, -79.9450812), LatLng(40.4424726, -79.9450977),
    LatLng(40.4424856, -79.9451583), LatLng(40.4424197, -79.9451827),
    LatLng(40.4425345, -79.9457575), LatLng(40.4425189, -79.9457636),
    LatLng(40.4424159, -79.9458044), LatLng(40.4424289, -79.9458726),
    LatLng(40.4424165, -79.945877), LatLng(40.4424346, -79.9459553),
    LatLng(40.4424528, -79.9460341), LatLng(40.4424913, -79.9460205),
    LatLng(40.4424968, -79.9460435), LatLng(40.4426031, -79.9459999),
    LatLng(40.4427288, -79.9465607),
  ],
  'Hamerschlag Hall': [
    LatLng(40.4427493, -79.9468379), LatLng(40.4425008, -79.9469323),
    LatLng(40.442487, -79.9469951), LatLng(40.44248, -79.9469996),
    LatLng(40.4423781, -79.9470346), LatLng(40.4423416, -79.9470224),
    LatLng(40.4423361, -79.9469935), LatLng(40.4422346, -79.9470329),
    LatLng(40.4420975, -79.9470795), LatLng(40.4420915, -79.9470406),
    LatLng(40.4420633, -79.9468903), LatLng(40.4422207, -79.9468346),
    LatLng(40.4422094, -79.9467902), LatLng(40.442183, -79.9466654),
    LatLng(40.4421431, -79.94648), LatLng(40.4421317, -79.9464257),
    LatLng(40.4421957, -79.9464031), LatLng(40.4421886, -79.9463608),
    LatLng(40.442283, -79.9463285), LatLng(40.4423783, -79.9462926),
    LatLng(40.4423868, -79.9463355), LatLng(40.4424583, -79.9463098),
    LatLng(40.4425563, -79.9467802), LatLng(40.4427163, -79.9467252),
    LatLng(40.4427193, -79.9467396),
  ],
};

/// Ray-casting point-in-polygon test.
bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
  int crossings = 0;
  for (int i = 0; i < polygon.length; i++) {
    final a = polygon[i];
    final b = polygon[(i + 1) % polygon.length];
    if ((a.latitude <= point.latitude && b.latitude > point.latitude) ||
        (b.latitude <= point.latitude && a.latitude > point.latitude)) {
      final t = (point.latitude - a.latitude) / (b.latitude - a.latitude);
      if (point.longitude < a.longitude + t * (b.longitude - a.longitude)) {
        crossings++;
      }
    }
  }
  return crossings.isOdd;
}

// ---------------------------------------------------------------------------
// HomePage
// ---------------------------------------------------------------------------

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  static const String routeName = '/home';
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  final BaseCacheManager _cacheManager = DefaultCacheManager();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<LocationProvider>().initialize();
        context.read<RestroomProvider>().loadRestrooms();
      }
    });
  }

  void _centerOnUser() {
    final lp = context.read<LocationProvider>();
    if (lp.hasPermission && lp.currentLocation != null) {
      _mapController.move(lp.currentLocation!, 16);
    }
  }

  /// Called when the user taps the map.  If the tap lands inside a building
  /// polygon, navigate to the building detail page.
  void _handleMapTap(TapPosition _, LatLng latLng, Map<String, List<Restroom>> byBuilding) {
    for (final entry in kBuildingPolygons.entries) {
      if (_isPointInPolygon(latLng, entry.value)) {
        final restrooms = byBuilding[entry.key];
        if (restrooms != null && restrooms.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  BuildingMapPage(building: entry.key, restrooms: restrooms),
            ),
          );
        }
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final restroomProvider = context.watch<RestroomProvider>();
    final locationProvider = context.watch<LocationProvider>();
    final userLocation =
        locationProvider.currentLocation ?? LatLng(40.4433, -79.9436);
    final restrooms = restroomProvider.restrooms;

    // Group restrooms by building.
    final Map<String, List<Restroom>> byBuilding = {};
    for (final r in restrooms) {
      byBuilding.putIfAbsent(r.building, () => []).add(r);
    }

    // Compute building centres for distance calculation.
    final Map<String, LatLng> buildingCenters = {};
    for (final entry in byBuilding.entries) {
      final list = entry.value;
      final lat =
          list.map((r) => r.latitude).reduce((a, b) => a + b) / list.length;
      final lon =
          list.map((r) => r.longitude).reduce((a, b) => a + b) / list.length;
      buildingCenters[entry.key] = LatLng(lat, lon);
    }

    // Build the polygon layer — white outlines, no fill.
    final List<Polygon> polygons = kBuildingPolygons.entries
        .where((e) => byBuilding.containsKey(e.key))
        .map((e) => Polygon(
              points: e.value,
              color: Colors.white.withOpacity(0.04),
              borderColor: Colors.white.withOpacity(0.55),
              borderStrokeWidth: 1.8,
            ))
        .toList();

    // Building name labels placed at each polygon center.
    final List<Marker> buildingLabels = kBuildingPolygons.entries
        .where((e) => byBuilding.containsKey(e.key))
        .map((e) {
      final pts = e.value;
      final cLat = pts.map((p) => p.latitude).reduce((a, b) => a + b) / pts.length;
      final cLng = pts.map((p) => p.longitude).reduce((a, b) => a + b) / pts.length;
      // Short label
      String label = e.key;
      if (label.length > 18) {
        label = label.replaceAll('School of Business', 'Business')
            .replaceAll('University Center', 'UC')
            .replaceAll('Center for the Arts', 'Arts')
            .replaceAll('College of Fine Arts', 'CFA')
            .replaceAll(' and ', ' & ')
            .replaceAll(' Centers', '')
            .replaceAll(' Hall', '');
      }
      return Marker(
        width: 120,
        height: 28,
        point: LatLng(cLat, cLng),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.7),
              letterSpacing: 0.3,
            ),
          ),
        ),
      );
    }).toList();

    final query = _searchController.text.toLowerCase();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Map ──────────────────────────────────────────────
            SizedBox.expand(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: userLocation,
                  initialZoom: 16.0,
                  maxZoom: 19.0,
                  minZoom: 14.0,
                  onTap: (pos, latLng) => _handleMapTap(pos, latLng, byBuilding),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.example.toilet_app',
                    tileProvider: CachedTileProvider(_cacheManager),
                  ),
                  // White building outlines
                  if (polygons.isNotEmpty) PolygonLayer(polygons: polygons),
                  // Building name labels
                  if (buildingLabels.isNotEmpty) MarkerLayer(markers: buildingLabels),
                  // User location dot
                  if (locationProvider.hasPermission &&
                      locationProvider.currentLocation != null)
                    // Outer blue glow
                    CircleLayer(circles: [
                      CircleMarker(
                        point: locationProvider.currentLocation!,
                        radius: 40,
                        color: const Color(0xFF007AFF).withOpacity(0.12),
                        borderStrokeWidth: 0,
                      ),
                    ]),
                    MarkerLayer(markers: [
                      Marker(
                        width: 16,
                        height: 16,
                        point: locationProvider.currentLocation!,
                        child: _buildUserMarker(),
                      ),
                    ]),
                ],
              ),
            ),

            // ── Location permission banner ───────────────────────
            if (!locationProvider.hasPermission && !locationProvider.isLoading)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFFC41230).withOpacity(0.5)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.location_off, color: Color(0xFFC41230)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Location access needed',
                          style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 13)),
                    ),
                    TextButton(
                      onPressed: () => locationProvider.requestPermission(),
                      child: const Text('Enable'),
                    ),
                  ]),
                ),
              ),

            // ── Search bar ───────────────────────────────────────
            Positioned(
              top: locationProvider.hasPermission ? 12 : 80,
              left: 16,
              right: 16,
              child: Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFC41230),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      const Icon(Icons.bolt, size: 22, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF111111),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF2A2A2A)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style:
                          GoogleFonts.inter(fontSize: 14, color: Colors.white),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search,
                            color: Color(0xFF666666), size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    size: 18, color: Color(0xFF666666)),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : const Icon(Icons.tune,
                                color: Color(0xFF666666), size: 20),
                        hintText: 'Search buildings...',
                        hintStyle: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF555555)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                      ),
                    ),
                  ),
                ),
              ]),
            ),

            // ── My-location FAB ──────────────────────────────────
            if (locationProvider.hasPermission)
              Positioned(
                right: 16,
                bottom: 240,
                child: FloatingActionButton.small(
                  heroTag: 'location',
                  onPressed: _centerOnUser,
                  backgroundColor: const Color(0xFF111111),
                  child: const Icon(Icons.my_location,
                      color: Colors.white, size: 20),
                ),
              ),

            // ── Bottom sheet — buildings list ────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBuildingSheet(
                  byBuilding, buildingCenters, userLocation, query),
            ),
          ],
        ),
      ),
    );
  }

  // ── Small widgets ────────────────────────────────────────────────────────

  Widget _buildUserMarker() {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: const Color(0xFF007AFF),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRow(double rating, {double size = 14}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < rating.floor()) {
          return Icon(Icons.star_rounded,
              size: size, color: const Color(0xFFC41230));
        } else if (i < rating.ceil() && rating - rating.floor() >= 0.5) {
          return Icon(Icons.star_half_rounded,
              size: size, color: const Color(0xFFC41230));
        } else {
          return Icon(Icons.star_outline_rounded,
              size: size, color: const Color(0xFF333333));
        }
      }),
    );
  }

  // ── Bottom sheet ─────────────────────────────────────────────────────────

  Widget _buildBuildingSheet(
      Map<String, List<Restroom>> byBuilding,
      Map<String, LatLng> buildingCenters,
      LatLng userLocation,
      String query) {
    final filteredBuildings = query.isEmpty
        ? byBuilding.keys.toList()
        : byBuilding.keys
            .where((b) => b.toLowerCase().contains(query))
            .toList();

    filteredBuildings.sort((a, b) {
      final da = buildingCenters[a] != null
          ? Distance()
              .as(LengthUnit.Meter, userLocation, buildingCenters[a]!)
          : double.infinity;
      final db = buildingCenters[b] != null
          ? Distance()
              .as(LengthUnit.Meter, userLocation, buildingCenters[b]!)
          : double.infinity;
      return da.compareTo(db);
    });

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(children: [
              Text('Buildings',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFC41230),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${filteredBuildings.length}',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ]),
          ),
          SizedBox(
            height: 200,
            child: filteredBuildings.isEmpty
                ? Center(
                    child: Text(
                      query.isEmpty
                          ? 'Loading buildings...'
                          : 'No buildings match "$query"',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: const Color(0xFF666666)),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredBuildings.length,
                    itemBuilder: (context, index) {
                      final building = filteredBuildings[index];
                      final bRestrooms = byBuilding[building]!;
                      final floors =
                          bRestrooms.map((r) => r.floor).toSet().length;
                      final avgRating = bRestrooms
                              .map((r) => r.generalRating)
                              .reduce((a, b) => a + b) /
                          bRestrooms.length;
                      final dist = buildingCenters[building] != null
                          ? Distance().as(LengthUnit.Meter, userLocation,
                              buildingCenters[building]!)
                          : 0.0;

                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BuildingMapPage(
                                building: building,
                                restrooms: bRestrooms),
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFC41230)
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.apartment,
                                  color: Color(0xFFC41230), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(building,
                                      style: GoogleFonts.inter(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${bRestrooms.length} restrooms \u00b7 $floors ${floors == 1 ? 'floor' : 'floors'}',
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: const Color(0xFF888888)),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    _buildStarRow(avgRating),
                                    const SizedBox(width: 6),
                                    Text(avgRating.toStringAsFixed(1),
                                        style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color:
                                                const Color(0xFF888888))),
                                  ]),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF222222),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('${dist.toStringAsFixed(0)}m',
                                  style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF888888))),
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cached tile provider (unchanged)
// ---------------------------------------------------------------------------

class CachedTileProvider extends TileProvider {
  CachedTileProvider(this.cache);
  final BaseCacheManager cache;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final url = getTileUrl(coordinates, options);
    return CachedNetworkImageProvider(url, cacheManager: cache);
  }
}
