import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const seedSkillsTaxonomy = functions.region("europe-west1").pubsub.schedule('every 24 hours').onRun(async (context) => {
  const skills = [
    { name: 'Flutter', category: 'technical', aliases: ['Dart', 'Flutter Framework'], popularity: 100 },
    { name: 'React', category: 'technical', aliases: ['ReactJS', 'React.js'], popularity: 95 },
    { name: 'TypeScript', category: 'technical', aliases: ['TS'], popularity: 90 },
    { name: 'Python', category: 'technical', aliases: ['Py'], popularity: 85 },
    { name: 'English', category: 'language', popularity: 100 },
    { name: 'Spanish', category: 'language', popularity: 100 },
    { name: 'Project Management', category: 'soft', popularity: 80 },
    { name: 'Team Leadership', category: 'soft', popularity: 85 },
  ];

  const batch = admin.firestore().batch();
  const skillsCol = admin.firestore().collection('skillsTaxonomy');

  for (const skill of skills) {
    const docId = skill.name.toLowerCase().replace(/\s+/g, '_');
    const docRef = skillsCol.doc(docId);
    batch.set(docRef, {
      ...skill,
      id: docId,
      relatedSkills: [],
    }, { merge: true });
  }

  await batch.commit();
  console.log('Skills taxonomy seeded successfully');
});
