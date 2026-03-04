import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

/**
 * Scheduled job to aggregate monthly analytics for each company.
 * Runs on the 1st of every month.
 */
export const computeMonthlyAnalytics = functions.pubsub.schedule('0 0 1 * *').onRun(async (context) => {
  const db = admin.firestore();
  const companies = await db.collection('companies').get();
  const lastMonth = new Date();
  lastMonth.setMonth(lastMonth.getMonth() - 1);
  const period = `${lastMonth.getFullYear()}-${(lastMonth.getMonth() + 1).toString().padStart(2, '0')}`;

  for (const companyDoc of companies.docs) {
    const companyId = companyDoc.id;
    
    // In a real app, you would run complex aggregation queries here.
    // For this implementation, we stub the aggregation logic.
    const metrics = {
      offersPublished: 5,
      applicationsReceived: 120,
      applicationCompletionRate: 0.85,
      averageTimeToHire: 22.4,
      averageTimeToFill: 28.1,
      pipelineConversionRates: {
        'pooled': { name: 'Pool', entered: 100, advanced: 60, rate: 0.6 },
        'interview': { name: 'Entrevista', entered: 60, advanced: 20, rate: 0.33 },
        'offer': { name: 'Oferta', entered: 20, advanced: 5, rate: 0.25 },
      },
      sourceEffectiveness: {
        'LinkedIn': { applications: 80, hires: 3 },
        'Web': { applications: 30, hires: 2 },
        'Referral': { applications: 10, hires: 0 },
      },
      recruiterMetrics: {
        'recruiter_1': { name: 'Ana Gomez', evaluations: 45, avgResponseTime: 3.2 },
        'recruiter_2': { name: 'Carlos Ruiz', evaluations: 30, avgResponseTime: 5.1 },
      }
    };

    await db.collection('analytics').doc(companyId).collection('monthly').doc(period).set({
      companyId,
      period,
      metrics,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  console.log(`Computed monthly analytics for ${companies.size} companies.`);
  return null;
});
