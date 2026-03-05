import * as functions from 'firebase-functions';

/**
 * Trigger to track status changes and calculate metrics like Time-to-Hire.
 */
export const onApplicationStatusChange = functions.region("europe-west1").firestore
  .document('applications/{applicationId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    // Track when an application moves to 'hired'
    if (before.status !== 'hired' && after.status === 'hired') {
      const createdAt = after.createdAt?.toDate() || after.submittedAt?.toDate();
      const hiredAt = new Date();
      
      if (createdAt) {
        const timeToHireDays = (hiredAt.getTime() - createdAt.getTime()) / (1000 * 60 * 60 * 24);
        
        console.log(`Application ${context.params.applicationId} hired in ${timeToHireDays} days.`);
        
        // In a real app, you would update a "running average" in a daily/monthly metrics doc
        // or log an event to a dedicated events collection for later aggregation.
      }
    }

    return null;
  });
