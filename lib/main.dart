import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const SalonApp());
}

// DONNEES EN MEMOIRE (STATE)
// ============================
class SalonData{
  static String nomSalon = "SALON XXXXXX";
  static String commune = "";
  static String avanue = "";
  static String telephone = "";

  static List<Map<String, dynamic>> coiffeurs = [
    {'nom': 'Coiffeur A', 'clients': 0, 'icone' : Icons.brush},
    {'nom': 'Coiffeur B', 'clients': 0, 'icone' : Icons.air},
    {'nom': 'Coiffeur C', 'clients': 0, 'icone' : Icons.content_cut},
    {'nom': 'Coiffeur D', 'clients': 0, 'icone' : Icons.face},
    {'nom': 'Coiffeur E', 'clients': 0, 'icone' : Icons.cut},
    {'nom': 'Coiffeur F', 'clients': 0, 'icone' : Icons.brush,}
    {'nom': 'Coiffeur G', 'clients': 0, 'icone' : Icons.air},
    {'nom': 'Coiffeur H', 'clients': 0, 'icone' : Icons.face},
  ];

  static double totalEntrees = 0;
  static double totalSorties = 0;
  static List<double> notes = [];

  static double get soldeCaisse => totalEntrees - totalSorties;
  static int get totalClients => coiffeurs.fold(0, (sum, item) => sum + (item['clients'] as int));
  static double get coteMoyenne => notes.isEmpty ? 4.5 : notes.reduce((a, b) => a + b)/ notes.length;
}


// Configuration du routeur avec les différents écrans
final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    // 1. Écran de bienvenue / Login Part 1
    GoRoute(
      path: '/',
      builder: (context, state) => const Loginscreen(),
    ),
    // 3. Tableau de bord
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    // 4. Historique
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
    ),
    // 5. Caisse
    GoRoute(
      path: '/caisse',
      builder: (context, state) => const CaisseScreen(),
    ),
  ],
);

class SalonApp extends StatelessWidget {
  const SalonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Coif-Hair',
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.red,
      ),
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nomSalonController = TextEditingController();
  final TextEditingController _communeController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _avenueController = TextEditingController
  
  bool _isLoading = false;

  // Fonction intelligente : Vérifier ou Créer le salon
  Future<void> _validerEtEntrer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; });

    try {
      final nomSalon = _nomSalonController.text.trim();
      final telephone = _telephoneController.text.trim();

      // 1. On cherche si un salon avec ce nom et ce téléphone existe déjà
      final querySnapshot = await FirebaseFirestore.instance
          .collection('salons')
          .where('nomSalon', isEqualTo: nomSalon)
          .where('telephoneProprio', isEqualTo: telephone)
          .get();

      String salonId;

      if (querySnapshot.docs.isNotEmpty) {
        // LE SALON EXISTE DÉJÀ : On récupère son ID existant
        salonId = querySnapshot.docs.first.id;
        
        // Petit message pour informer l'utilisateur gentiment
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Salon reconnu ! Connexion au tableau de bord...')),
        );
      } else {
        // LE SALON N'EXISTE PAS : On le crée dans Firestore
        final docRef = await FirebaseFirestore.instance.collection('salons').add({
          'nomSalon': nomSalon,
          'avenue': _avenueController.text.trim(),
          'commune': _communeController.text.trim(),
          'telephoneProprio': telephone,
          'compteurClientsActuel': 0,
          'dateCreation': FieldValue.serverTimestamp(),
        });
        
        salonId = docRef.id;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nouveau salon créé avec succès !')),
        );
      }

      // 2. Navigation vers le tableau des coiffeurs en passant le salonId
      SalonData.salonId = salonId;
      context.go('/dashboard');

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de connexion : $e')),
      );
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CoifHair Manager - Connexion')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Bienvenue ! ',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Entrez les informations du salon pour y accéder ou le configurer.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              
              // Nom du Salon
              TextFormField(
                controller: _nomSalonController,
                decoration: const InputDecoration(
                  labelText: 'Nom du Salon',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Entrez le nom du salon' : null,
              ),
              const SizedBox(height: 15),

              // Commune
              TextFormField(
                controller: _adresseController,
                decoration: const InputDecoration(
                  labelText: 'Adresse ou Commune (ex: Gombe)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Entrez l\'adresse' : null,

              // Avenue
              TextFormField(
                controller: _avenueController,
                decoration: const InputDecoration(
                  labelText: 'Avenue',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Entrez le nom de l\'avenue' : null,
              ),
              const SizedBox(height: 15),

              // Numéro de téléphone du propriétaire
              TextFormField(
                controller: _telephoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Téléphone du Propriétaire / Gérant',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Entre un numéro valide' : null,
              ),
              const SizedBox(height: 30),

              // Bouton unique intelligent
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      onPressed: _validerEtEntrer,
                      child: const Text('Accéder au Salon', style: TextStyle(fontSize: 18)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

// =================================================================
// 3. TABLEAU DE BORD Dashboard complet et corrigé
// =================================================================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Fonction pour renommer un coiffeur directement en cliquant dessus
  void renommerCoiffeur(BuildContext context, int index) {
    final TextEditingController controller = TextEditingController(
      text: SalonData.coiffeurs[index]['nom'],
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifier le nom'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Nom du coiffeur',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    SalonData.coiffeurs[index]['nom'] = controller.text.trim();
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }
  // Fonction pour afficher le message de blocage de la version gratuite
  void _afficherAlertePaywall(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Version d\'essai expirée '),
          content: const Text(
            'Vous avez atteint la limite de 50 clients de la version gratuite.\n\nVeuillez contacter le développeur pour passer à la version payante et débloquer un accès illimité !',
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Compris'),
            ),
          ],
        );
      },
    );
  },  
  // Fonction d'ajout de prestation 
  void afficherDialogueAjoutClient(BuildContext context, VoidCallback onUpdate) {
    String? coiffeurSelectionne = SalonData.coiffeurs.isNotEmpty ? SalonData.coiffeurs[0]['nom'] : null;
    final TextEditingController montantController = TextEditingController();
    double noteAttribuee = 5.0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Ajouter une prestation'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Choisir le coiffeur :', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: coiffeurSelectionne,
                    items: SalonData.coiffeurs.map((c) {
                      return DropdownMenuItem<String>(
                        value: c['nom'] as String,
                        child: Text(c['nom']),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setStateDialog(() {
                        coiffeurSelectionne = val;
                      });
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: montantController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Montant perçu (CDF)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Note du client :', style: TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: noteAttribuee,
                    min: 1.0,
                    max: 5.0,
                    divisions: 4,
                    label: noteAttribuee.toString(),
                    activeColor: Colors.orange,
                    onChanged: (val) {
                      setStateDialog(() {
                        noteAttribuee = val;
                      });
                    },
                  ),
                  Center(
                    child: Text(
                      '${noteAttribuee.toStringAsFixed(1)} ⭐',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    final double montant = double.tryParse(montantController.text) ?? 0;
                    if (montant > 0 && coiffeurSelectionne != null) {
                      for (var c in SalonData.coiffeurs) {
                        if (c['nom'] == coiffeurSelectionne) {
                          c['clients'] = (c['clients'] as int) + 1;
                        }
                      }
                      SalonData.totalEntrees += montant;
                      SalonData.notes.add(noteAttribuee);

                      Navigator.pop(context);
                      onUpdate();
                    }
                  },
                  child: const Text('Valider'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Récupération de la date du système en temps réel
    final now = DateTime.now();
    final String dateDuJour = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // --- EN-TÊTE ROUGE ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              color: Colors.red,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'COIF-HAIR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        SalonData.nomSalon,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.history, color: Colors.white),
                        onPressed: () => context.go('/history'),
                        tooltip: 'Historique',
                      ),
                      IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () => context.go('/'),
                        tooltip: 'Déconnexion',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --- INDICATEURS (Date + Badges Orange compacts + Icônes User & Caisse) ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DATE : $dateDuJour',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'CLIENTS : ${SalonData.totalClients.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'CÔTE MOYENNE : ${SalonData.coteMoyenne.toStringAsFixed(1)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade400, width: 1.5),
                        ),
                        child: const Icon(Icons.person_outline, color: Colors.black87, size: 22),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => context.go('/caisse'),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red.shade50,
                            border: Border.all(color: Colors.red, width: 1.5),
                          ),
                          child: const Icon(Icons.point_of_sale, color: Colors.red, size: 22),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --- GRILLE DÉFILANTE DES COIFFEURS ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.05,
                  ),
                  itemCount: SalonData.coiffeurs.length,
                  itemBuilder: (context, index) {
                    final coiffeur = SalonData.coiffeurs[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => _renommerCoiffeur(context, index),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                 coiffeur['nom'],
                                 style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.edit, size: 14, color: Colors.grey),
                              ],
                            ),
                          ),

                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(coiffeur['icone'], color: Colors.red, size: 28),
                              const SizedBox(width: 8),
                              Text(
                                '${(coiffeur['clients'] as int).toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 38,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            'Clients',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            
            
            
            // FONCTION BOUTON D'ACTION EN BAS ("Ajouter une prestation") ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextButton.icon(
                    onPressed: () {
                      // Vérification de la limite de la version gratuite
                      if (SalonData.totalClients >= 50) {
                        _afficherAlertePaywall(context);
                      } else {
                        afficherDialogueAjoutClient(context, () {
                          setState(() {}); // rafraîchit l'écran du tableau de bord
                        });
                      }
                    },
                    icon: const Icon(Icons.add, color: Colors.red),
                    label: const Text(
                      'Ajouter une prestation',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =================================================================
// 4. ÉCRAN CAISSE (Basé sur le croquis : Entrées, Sorties, Solde, Dépense)
// =================================================================
class CaisseScreen extends StatefulWidget {
  const CaisseScreen({super.key});

  @override
  State<CaisseScreen> createState() => _CaisseScreenState();
}

class _CaisseScreenState extends State<CaisseScreen> {
  void afficherDialogueDepense(BuildContext context) {
    final TextEditingController montantController = TextEditingController();
    final TextEditingController explicationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enregistrer une dépense'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: montantController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Montant',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: explicationController,
                decoration: const InputDecoration(
                  labelText: 'Explication',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
            ),
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.red, size: 36),
              onPressed: () {
                final double montant = double.tryParse(montantController.text) ?? 0;
                if (montant > 0) {
                  setState(() {
                    SalonData.totalSorties += montant;
                  });
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caisse'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Entrées et Sorties côte à côte
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Entrées', style: TextStyle(color: Colors.grey, fontSize: 14)),
                          const SizedBox(height: 8),
                          Text('${SalonData.totalEntrees.toInt()}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                          const Text('CDF', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Sorties', style: TextStyle(color: Colors.grey, fontSize: 14)),
                          const SizedBox(height: 8),
                          Text('${SalonData.totalSorties.toInt()}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)),
                          const Text('CDF', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Solde net en caisse
            Card(
              elevation: 2,
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Solde net en Caisse', style: TextStyle(color: Colors.orange, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('${SalonData.soldeCaisse.toInt()} CDF', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.orange)),
                  ],
                ),
              ),
            ),
            const Spacer(),
            // Bouton pour ajouter une dépense
            Center(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextButton.icon(
                  onPressed: () => afficherDialogueDepense(context),
                  icon: const Icon(Icons.add_circle_outline, color: Colors.red),
                  label: const Text(
                    'Ajouter une dépense',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =================================================================
// BLOC 3 (suite) : ÉCRAN HISTORIQUE CONNECTÉ
// =================================================================
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Récupération de la date du système en temps réel
    final now = DateTime.now();
    final String dateDuJour = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    // Uniquement la session actuelle (fin des fausses données)
    final List<Map<String, dynamic>> historiqueJours = [
      {
        'date': dateDuJour, 
        'clients': SalonData.totalClients, 
        'cote': SalonData.coteMoyenne.toStringAsFixed(1), 
        'recette': '${SalonData.totalEntrees.toInt()} CDF'
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des journées'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: historiqueJours.length,
        itemBuilder: (context, index) {
          final jour = historiqueJours[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(
                'Date : ${jour['date']}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text(
                  'Clients : ${jour['clients']} | Côte : ${jour['cote']} ⭐',
                  style: const TextStyle(color: Colors.black87),
                ),
              ),
              trailing: Text(
                jour['recette'],
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
