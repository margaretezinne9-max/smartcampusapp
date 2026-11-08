import 'package:flutter/widgets.dart';

import '../settings/app_settings.dart';

/// Lightweight English/French support.
///
/// The English text IS the key: `context.tr('Next class')`. In English the
/// text is returned as written; in French it is looked up in [_fr]. A string
/// with no French entry simply stays in English, so nothing ever breaks.
/// Placeholders such as {name} are filled from the second argument.
String translate(
  String text,
  String lang, [
  Map<String, String> params = const {},
]) {
  var result = lang == 'fr' ? (_fr[text] ?? text) : text;
  params.forEach((key, value) => result = result.replaceAll('{$key}', value));
  return result;
}

extension AppLocalization on BuildContext {
  /// 'en' or 'fr'. English when the app has no settings scope.
  String get lang => AppSettingsScope.maybeOf(this)?.language ?? 'en';

  String tr(String text, [Map<String, String> params = const {}]) =>
      translate(text, lang, params);
}

const _fr = <String, String>{
  // Navigation and roles
  'Home': 'Accueil',
  'Profile': 'Profil',
  'Timetable': 'Horaire',
  'Notices': 'Avis',
  'Results': 'Résultats',
  'Students': 'Étudiants',
  'Users': 'Utilisateurs',
  'Attendance': 'Présences',
  'Payments': 'Paiements',
  'Receipts': 'Reçus',
  'Application': 'Candidature',
  'Admission': 'Admission',
  'Student': 'Étudiant',
  'Lecturer': 'Enseignant',
  'Bursar': 'Économe',
  'Administrator': 'Administrateur',
  'Course Rep': 'Délégué de classe',
  'Aspirant': 'Candidat',
  'Your weekly classes with hall and campus.':
      'Vos cours de la semaine avec la salle et le campus.',
  'Announcements and upcoming campus events.':
      'Annonces et prochains événements du campus.',
  'Semester results and transcript requests.':
      'Résultats du semestre et demandes de relevé de notes.',
  'The classes you teach, with hall and campus.':
      'Les cours que vous enseignez, avec la salle et le campus.',
  'Students enrolled in your courses.': 'Étudiants inscrits à vos cours.',
  'Publish and remove notices and events.':
      'Publier et supprimer des avis et des événements.',
  'See every account and change its role.':
      'Voir tous les comptes et modifier leur rôle.',
  'Your class timetable with hall and campus.':
      'Votre emploi du temps avec la salle et le campus.',
  'Record and review class attendance.':
      'Enregistrer et consulter les présences en classe.',
  'Incoming payments and verification queue.':
      'Paiements reçus et file de vérification.',
  'Issue, search and reprint receipts.':
      'Émettre, rechercher et réimprimer des reçus.',
  'Personal details, programme choice and documents.':
      'Informations personnelles, choix de filière et documents.',
  'Check your admission decision and next steps.':
      "Consultez votre décision d'admission et les prochaines étapes.",

  // Login
  'Create your applicant account': 'Créez votre compte de candidat',
  'Sign in to your campus portal': 'Connectez-vous à votre portail du campus',
  'Full name': 'Nom complet',
  'Enter your full name.': 'Entrez votre nom complet.',
  'Email address': 'Adresse e-mail',
  'University email': 'E-mail universitaire',
  'Enter a valid email address.': 'Entrez une adresse e-mail valide.',
  'Password': 'Mot de passe',
  'Show password': 'Afficher le mot de passe',
  'Hide password': 'Masquer le mot de passe',
  'Password must be at least 6 characters.':
      'Le mot de passe doit contenir au moins 6 caractères.',
  'Create account': 'Créer un compte',
  'Sign in': 'Se connecter',
  'Already have an account? Sign in': 'Déjà un compte ? Se connecter',
  'New applicant? Create an account': 'Nouveau candidat ? Créez un compte',
  'Demo accounts (debug builds only)':
      'Comptes de démonstration (mode debug uniquement)',
  'Email or password is incorrect.': 'E-mail ou mot de passe incorrect.',
  'An account with this email already exists.':
      'Un compte existe déjà avec cet e-mail.',
  'Could not reach the server. Check your connection and try again.': 'Impossible de joindre le serveur. Vérifiez votre connexion et réessayez.',
  'Password is too weak. Use at least 6 characters.':
      'Mot de passe trop faible. Utilisez au moins 6 caractères.',
  'This account has been disabled.': 'Ce compte a été désactivé.',
  'Too many attempts. Please try again later.':
      'Trop de tentatives. Réessayez plus tard.',
  'No internet connection. Check your network.':
      'Pas de connexion Internet. Vérifiez votre réseau.',

  // Profile and settings
  'Sign out': 'Se déconnecter',
  'Settings': 'Paramètres',
  'Language': 'Langue',
  'Theme': 'Thème',
  'System': 'Système',
  'Light': 'Clair',
  'Dark': 'Sombre',
  'Class reminder': 'Rappel de cours',
  'Off': 'Désactivé',
  '{n} min before class': '{n} min avant le cours',
  'Reminders appear in the app while it is open.':
      "Les rappels s'affichent dans l'application tant qu'elle est ouverte.",

  // Home, reminders, events
  'Welcome, {name}': 'Bienvenue, {name}',
  'Your next class and the latest campus notices.':
      'Votre prochain cours et les derniers avis du campus.',
  'Latest notices': 'Derniers avis',
  'No notices yet.': "Aucun avis pour l'instant.",
  'No classes are assigned to you yet.':
      "Aucun cours ne vous est encore attribué.",
  'No classes on your timetable yet.':
      "Aucun cours dans votre emploi du temps pour l'instant.",
  'Happening now': 'En cours',
  'Next class': 'Prochain cours',
  'Ends in {time}': 'Se termine dans {time}',
  'Starts in {time}': 'Commence dans {time}',
  'Hall and campus info': 'Salle et campus',
  '{day}, {start} to {end}': '{day}, de {start} à {end}',
  'Upcoming events': 'Événements à venir',
  'In {n} days': 'Dans {n} jours',
  'Today': "Aujourd'hui",
  'Tomorrow': 'Demain',
  '{course} starts in {time}. {hall}, {campus}.':
      '{course} commence dans {time}. {hall}, {campus}.',
  'Dismiss': 'Fermer',

  // Timetable and campus info
  'My timetable': 'Mon emploi du temps',
  'Your timetable is empty for now.':
      "Votre emploi du temps est vide pour l'instant.",
  '{department}, level {level}': '{department}, niveau {level}',
  'No directions have been added for this campus yet.':
      "Aucun itinéraire n'a encore été ajouté pour ce campus.",
  'How to get there': 'Comment y aller',
  'No written directions yet.': "Pas encore d'indications écrites.",
  'Open in Google Maps': 'Ouvrir dans Google Maps',
  'Could not open Google Maps. Use the written directions.':
      "Impossible d'ouvrir Google Maps. Utilisez les indications écrites.",

  // Notices
  'Notices and events': 'Avis et événements',
  'No notices have been published.': "Aucun avis n'a été publié.",
  'Publish notice': 'Publier un avis',
  'Publish a notice': 'Publier un avis',
  'Notice': 'Avis',
  'Event': 'Événement',
  'Title': 'Titre',
  'Enter a title.': 'Entrez un titre.',
  'Details': 'Détails',
  'Enter the details.': 'Entrez les détails.',
  'Pick event date': "Choisir la date de l'événement",
  'Pick the event date.': "Choisissez la date de l'événement.",
  'Could not publish. Check your connection and permissions.':
      'Publication impossible. Vérifiez votre connexion et vos droits.',
  'Cancel': 'Annuler',
  'Publish': 'Publier',
  'Audience': 'Public concerné',
  'All departments': 'Tous les départements',
  'All levels': 'Tous les niveaux',
  'Level {n}': 'Niveau {n}',
  'Delete notice': "Supprimer l'avis",
  'Event date: {date}': "Date de l'événement : {date}",
  'Posted {date}': 'Publié le {date}',
  'For {audience}': 'Pour {audience}',

  // Lecturer, admin
  'My students': 'Mes étudiants',
  'No students are enrolled in your courses yet.':
      "Aucun étudiant n'est encore inscrit à vos cours.",
  '{n} student': '{n} étudiant',
  '{n} students': '{n} étudiants',
  'Change a role to give someone a different dashboard. They must sign in again to see it.': "Changez un rôle pour donner un autre tableau de bord à quelqu'un. La personne doit se reconnecter pour le voir.",
  '{name} is now {role}.': '{name} est maintenant {role}.',
  'Could not change the role.': 'Impossible de modifier le rôle.',
  'You': 'Vous',
  'Publish notices and manage who can access what.':
      'Publiez des avis et gérez les accès de chacun.',
  'Registered users': 'Utilisateurs inscrits',
  'Published notices': 'Avis publiés',
  'Load demo data': 'Charger les données de démonstration',
  'Sample campuses, timetable, notices and enrolments for testing and evaluation.': "Campus, emploi du temps, avis et inscriptions d'exemple pour les tests et l'évaluation.",
  'Load demo data?': 'Charger les données de démonstration ?',
  'This adds two campuses, a weekly timetable, sample notices and enrolments for Computer Science level 400. It also assigns that department and level to every student and course rep. Set roles in the Users tab first.': "Cela ajoute deux campus, un emploi du temps hebdomadaire, des avis d'exemple et des inscriptions pour Computer Science niveau 400. Cela attribue aussi ce département et ce niveau à chaque étudiant et délégué de classe. Définissez d'abord les rôles dans l'onglet Utilisateurs.",
  'Load data': 'Charger',
  'Demo data loaded. Students must sign in again.':
      'Données chargées. Les étudiants doivent se reconnecter.',
  'Could not load demo data: {error}':
      'Impossible de charger les données : {error}',
  'Could not load this data.': 'Impossible de charger ces données.',

  // Chat, assistant, shortcuts
  'Chat': 'Discussion',
  'Assistant': 'Assistant',
  'Course chats with your lecturers and classmates.':
      'Discussions de cours avec vos enseignants et camarades.',
  'Message the students of your courses.':
      'Écrivez aux étudiants de vos cours.',
  'Ask academic questions and get study help.':
      "Posez des questions académiques et obtenez de l'aide pour étudier.",
  'All notices': 'Tous les avis',
  'Course chats': 'Discussions de cours',
  'You are not part of any course chat yet.':
      "Vous ne faites encore partie d'aucune discussion de cours.",
  'Write a message': 'Écrire un message',
  'No messages yet. Say hello!': 'Pas encore de messages. Dites bonjour !',
  'Could not send the message.': "Impossible d'envoyer le message.",
  'Send': 'Envoyer',
  'Ask a question': 'Posez votre question',
  'New conversation': 'Nouvelle conversation',
  'Try asking': 'Essayez par exemple',
  'Thinking...': 'Réflexion en cours...',
  'Ask me about your courses, exam revision and study methods.': "Posez-moi vos questions sur vos cours, la révision des examens et les méthodes d'étude.",
  'AI answers can contain mistakes. Check important information with your lecturers.': "Les réponses de l'IA peuvent contenir des erreurs. Vérifiez les informations importantes auprès de vos enseignants.",
  'Demo mode: answers come from a small built-in list, not a real AI.': "Mode démo : les réponses viennent d'une petite liste intégrée, pas d'une vraie IA.",
  'I can only help with academic questions: course content, study methods and exam revision.': "Je peux seulement aider pour les questions académiques : contenu des cours, méthodes d'étude et révision des examens.",
  'Explain what a deadlock is': "Explique ce qu'est un interblocage (deadlock)",
  'Help me revise database normalization':
      'Aide-moi à réviser la normalisation des bases de données',
  'Give me tips for exam revision':
      'Donne-moi des conseils pour réviser mes examens',
  'The assistant is unavailable right now. Please try again.':
      "L'assistant est indisponible pour le moment. Réessayez.",
  'The assistant did not return an answer. Try rephrasing your question.':
      "L'assistant n'a pas donné de réponse. Reformulez votre question.",
  'Your question is too long. Please shorten it.':
      'Votre question est trop longue. Veuillez la raccourcir.',
  'The assistant took too long to answer. Please try again.':
      "L'assistant a mis trop de temps à répondre. Réessayez.",
  'The assistant is very busy right now. Please try again in a minute.':
      "L'assistant est très sollicité en ce moment. Réessayez dans une minute.",

  // Exams, study planner, resources
  'Exams': 'Examens',
  'Next exam': 'Prochain examen',
  'Finished': 'Terminé',
  'Delete exam': "Supprimer l'examen",
  'Exams and study planner': "Examens et plan de révision",
  'Study planner': 'Plan de révision',
  'No exams have been scheduled yet.': "Aucun examen n'est encore programmé.",
  'Add exam': 'Ajouter un examen',
  'Course': 'Cours',
  'Pick the date': 'Choisir la date',
  'Pick the start time': "Choisir l'heure de début",
  'Duration': 'Durée',
  'Hall': 'Salle',
  'Save': 'Enregistrer',
  'Choose a course, a date and a time.':
      'Choisissez un cours, une date et une heure.',
  'Could not save the exam. Check your permissions.':
      "Impossible d'enregistrer l'examen. Vérifiez vos droits.",
  'How much can you study each day?':
      'Combien de temps pouvez-vous étudier par jour ?',
  'The closer an exam is, the more time it gets.':
      "Plus un examen est proche, plus il reçoit de temps.",
  'No upcoming exams to plan for.': "Aucun examen à venir à planifier.",
  'Manage exams': 'Gérer les examens',
  'Study resources': "Ressources d'étude",
  'No resources have been shared yet.':
      "Aucune ressource n'a encore été partagée.",
  'Notes': 'Notes de cours',
  'Past questions': 'Anciens sujets',
  'Other': 'Autre',
  'Delete resource': 'Supprimer la ressource',
  'Add resource': 'Ajouter une ressource',
  'Could not open the link.': "Impossible d'ouvrir le lien.",
  'Choose a course.': 'Choisissez un cours.',
  'Could not save the resource. Check your permissions.':
      "Impossible d'enregistrer la ressource. Vérifiez vos droits.",
  'Link (https://...)': 'Lien (https://...)',
  'Enter a secure link starting with https://':
      'Entrez un lien sécurisé commençant par https://',

  // Feedback and usability survey
  'Feedback': 'Commentaires',
  'Feedback and survey results': "Commentaires et résultats de l'enquête",
  'Your feedback is anonymous. Only your role is saved.':
      'Vos commentaires sont anonymes. Seul votre rôle est enregistré.',
  'Problem': 'Problème',
  'Idea': 'Idée',
  'How would you rate the app? (optional)':
      "Quelle note donnez-vous à l'application ? (facultatif)",
  'Your message': 'Votre message',
  'Send feedback': 'Envoyer',
  'Usability survey': "Enquête d'utilisabilité",
  'Ten quick questions (about 2 minutes) to help evaluate this app.': "Dix questions rapides (environ 2 minutes) pour aider à évaluer cette application.",
  'Thank you for your feedback.': 'Merci pour vos commentaires.',
  'Could not send your feedback. Please try again.':
      "Impossible d'envoyer vos commentaires. Réessayez.",
  'Please write your feedback.': 'Veuillez écrire vos commentaires.',
  'Your feedback is too long.': 'Vos commentaires sont trop longs.',
  'The rating must be between 1 and 5.':
      'La note doit être comprise entre 1 et 5.',
  'For each statement, choose how much you agree.':
      "Pour chaque affirmation, indiquez votre degré d'accord.",
  '1 = strongly disagree, 5 = strongly agree':
      "1 = pas du tout d'accord, 5 = tout à fait d'accord",
  'Submit survey': "Envoyer l'enquête",
  'Thank you for taking part.': 'Merci de votre participation.',
  'Could not send the survey. Please try again.':
      "Impossible d'envoyer l'enquête. Réessayez.",
  'Survey results': "Résultats de l'enquête",
  'Average SUS score (out of 100)': 'Score SUS moyen (sur 100)',
  '{n} response': '{n} réponse',
  '{n} responses': '{n} réponses',
  'Above the average of 68.': 'Au-dessus de la moyenne de 68.',
  'Below the average of 68.': 'En dessous de la moyenne de 68.',
  'No feedback yet.': 'Aucun commentaire pour le moment.',
  'I think that I would like to use this system frequently.':
      "Je pense que j'aimerais utiliser ce système fréquemment.",
  'I found the system unnecessarily complex.':
      "J'ai trouvé ce système inutilement complexe.",
  'I thought the system was easy to use.':
      "J'ai trouvé ce système facile à utiliser.",
  'I think that I would need the support of a technical person to be able to use this system.': "Je pense que j'aurais besoin de l'aide d'un technicien pour pouvoir utiliser ce système.",
  'I found the various functions in this system were well integrated.': "J'ai trouvé que les différentes fonctions de ce système étaient bien intégrées.",
  'I thought there was too much inconsistency in this system.':
      "J'ai trouvé qu'il y avait trop d'incohérences dans ce système.",
  'I would imagine that most people would learn to use this system very quickly.': "J'imagine que la plupart des gens apprendraient très vite à utiliser ce système.",
  'I found the system very cumbersome to use.':
      "J'ai trouvé ce système très lourd à utiliser.",
  'I felt very confident using the system.':
      "Je me suis senti(e) très en confiance en utilisant ce système.",
  'I needed to learn a lot of things before I could get going with this system.': "J'ai dû apprendre beaucoup de choses avant de pouvoir utiliser ce système.",

  // Additional home dashboard translations
  'Hello, {name}': 'Bienvenue, {name}',
  'Welcome back to your campus': 'Bienvenue sur votre campus',
  'No shortcuts available.': 'Aucun raccourci disponible.',
  'Next Class': 'Prochain cours',
  'Get directions': 'Obtenir un itinéraire',
  'Hall info': 'Informations sur la salle',
  'Campus events': 'Événements du campus',
  'Discover what is happening around your university.':
      'Découvrez ce qui se passe dans votre université.',
  'Upcoming': 'À venir',
  'Past events': 'Événements passés',
  'Coming up': 'Prochainement',
  'No upcoming events. Check back soon for campus activities.': 'Aucun événement à venir. Revenez bientôt pour découvrir les activités du campus.',
  'PAST EVENT': 'ÉVÉNEMENT PASSÉ',
  'CAMPUS EVENT': 'ÉVÉNEMENT DU CAMPUS',
  'No upcoming events.': 'Aucun événement à venir.',

  // Additional examination translations
  'Next Examination': 'Prochain examen',
  'Next Exam': 'Prochain examen',
  'Start Revision Plan': 'Commencer le programme de révision',
  'Examinations': 'Examens',
  'Stay prepared with your upcoming assessments and revision plan.': 'Préparez-vous à vos prochaines évaluations grâce à votre programme de révision.',
  'Completed': 'Terminés',

  // Additional notices and learning translations
  'Campus notices': 'Avis du campus',
  'Important updates and announcements from your university.':
      'Informations importantes et annonces de votre université.',
  'Latest updates': 'Dernières actualités',
  'Find lecture notes, past questions and helpful course materials.': 'Trouvez des notes de cours, des sujets d’examen précédents et des supports pédagogiques utiles.',
  'Your learning library': 'Votre bibliothèque pédagogique',
  'Your weekly classes, venues and campus locations at a glance.': 'Consultez en un coup d’œil vos cours hebdomadaires, leurs salles et les campus.',
  'Weekly schedule': 'Emploi du temps hebdomadaire',
  'Academic results': 'Résultats académiques',
  'Review your semester performance and course grades.':
      'Consultez vos résultats du semestre et vos notes par cours.',
  'Select semester': 'Sélectionner le semestre',

  // Results
  'My results': 'Mes résultats',
  'Semester': 'Semestre',
  'Semester GPA': 'Moyenne du semestre',
  'No results have been published yet.':
      "Aucun résultat n'a encore été publié.",
  '{units} units, score {score}': '{units} crédits, note {score}',
  'The assistant has reached its free usage limit for now. Please try again later.': "L'assistant a atteint sa limite d'utilisation gratuite pour le moment. Réessayez plus tard.",

  // Aspirant screens
  'Try again': 'Réessayer',
  'Could not load your application.':
      'Impossible de charger votre candidature.',
  'Something went wrong. Please try again.':
      "Une erreur s'est produite. Réessayez.",
  'Submission failed.': "L'envoi a échoué.",
  'Please attach all required documents.':
      'Veuillez joindre tous les documents requis.',
  'Please complete all steps before submitting.':
      "Veuillez terminer toutes les étapes avant d'envoyer.",
  'Admission application': "Dossier d'admission",
  'Your progress is saved each time you continue.':
      'Votre progression est enregistrée à chaque étape.',
  'Submit application': 'Envoyer la candidature',
  'Continue': 'Continuer',
  'Back': 'Retour',
  'Personal details': 'Informations personnelles',
  'Phone number': 'Numéro de téléphone',
  'Enter a valid phone number.': 'Entrez un numéro de téléphone valide.',
  'Date of birth': 'Date de naissance',
  'Select your date of birth.': 'Sélectionnez votre date de naissance.',
  'Home address': 'Adresse du domicile',
  'Enter your home address.': 'Entrez votre adresse.',
  'Programme choice': 'Choix de la filière',
  'Programme': 'Filière',
  'Choose a programme.': 'Choisissez une filière.',
  'Entrance exam score (0-{max})': "Note à l'examen d'entrée (0-{max})",
  'Enter a score between 0 and {max}.':
      'Entrez une note comprise entre 0 et {max}.',
  'Documents': 'Documents',
  'Demo mode: attaching only simulates an upload. Real uploads need the file_picker package and a storage backend.': "Mode démo : joindre un document simule seulement un envoi. Les vrais envois nécessitent le paquet file_picker et un espace de stockage.",
  'Attached': 'Joint',
  'Not attached': 'Non joint',
  'Remove': 'Retirer',
  'Attach': 'Joindre',
  'Review and submit': 'Vérifier et envoyer',
  'Phone': 'Téléphone',
  'Address': 'Adresse',
  'Exam score': "Note d'examen",
  '{n} of {m} attached': '{n} sur {m} joints',
  'You cannot edit your application after submitting.':
      "Vous ne pourrez plus modifier votre candidature après l'envoi.",
  'Application submitted': 'Candidature envoyée',
  'Submitted {date}': 'Envoyée le {date}',
  'Track your progress in the Admission tab.':
      "Suivez l'avancement dans l'onglet Admission.",
  'Computer Science': 'Informatique',
  'Accounting': 'Comptabilité',
  'Law': 'Droit',
  'Nursing Science': 'Sciences infirmières',
  'Mechanical Engineering': 'Génie mécanique',
  'Mass Communication': 'Communication de masse',
  'Birth certificate': 'Acte de naissance',
  "O'Level result": "Relevé de notes du secondaire (O'Level)",
  'Passport photograph': "Photo d'identité",
  'Admission status': "Statut d'admission",
  'Congratulations! You have been offered admission to study {programme} at Hill City University.': 'Félicitations ! Une admission vous est proposée en {programme} à Hill City University.',
  'You have not submitted your application yet. Complete the Application tab to start the admission process.': "Vous n'avez pas encore envoyé votre candidature. Remplissez l'onglet Candidature pour lancer le processus d'admission.",
  'Under review by admissions': "En cours d'examen par les admissions",
  'Admission decision': "Décision d'admission",
  'Refresh status': 'Actualiser le statut',
  'Demo mode: after you submit, the status moves to "Under review" after about 15 seconds and "Admitted" after about 40. Press Refresh to see it change. In production an admissions officer updates the status.': "Mode démo : après l'envoi, le statut passe à « En cours d'examen » après environ 15 secondes et à « Admis » après environ 40. Appuyez sur Actualiser pour voir le changement. En production, un responsable des admissions met le statut à jour.",

  // Bursar and aspirant dashboards
  'Quick actions': 'Actions rapides',
  'Track fee payments, receipts and reconciliation.':
      'Suivez les paiements des frais, les reçus et le rapprochement.',
  'Collected today': "Encaissé aujourd'hui",
  'Pending verifications': 'Vérifications en attente',
  'Defaulters': 'Retards de paiement',
  'Verify payments': 'Vérifier les paiements',
  'Match bank and gateway records':
      'Rapprocher les relevés bancaires et de la passerelle',
  'Generate report': 'Générer un rapport',
  'Daily and semester summaries': 'Résumés quotidiens et semestriels',
  'Complete your application to Hill City University.':
      'Complétez votre candidature à Hill City University.',
  'In progress': 'En cours',
  'Documents uploaded': 'Documents envoyés',
  '2 of 5': '2 sur 5',
  'Pending': 'En attente',
  'Continue application': 'Continuer la candidature',
  'Pick up where you stopped': 'Reprenez là où vous vous êtes arrêté',
  'Pay application fee': 'Payer les frais de dossier',
  'Required before submission': "Requis avant l'envoi",

  // Grades
  'No score yet': 'Pas encore de note',
  'Score: {score}': 'Note : {score}',
  'Edit score': 'Modifier la note',
  'Score (0-100)': 'Note (0-100)',
  'Enter a whole number from 0 to 100.': 'Entrez un nombre entier de 0 à 100.',
  'Could not save the score. Check your permissions.':
      "Impossible d'enregistrer la note. Vérifiez vos droits.",
  'Current semester': 'Semestre en cours',
};

/// The French dictionary, public so the tests can check that nothing is missing.
const Map<String, String> frenchStrings = _fr;
