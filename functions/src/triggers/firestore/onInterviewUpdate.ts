import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();

export const onInterviewUpdate = functions.firestore
  .document("interviews/{interviewId}")
  .onWrite(async (change, context) => {
    const newData = change.after.exists ? change.after.data() : null;
    const oldData = change.before.exists ? change.before.data() : null;
    const interviewId = context.params.interviewId;

    // Handle deletion
    if (!newData) {
        // Remove associated calendar events
        const snapshot = await db.collection("calendarEvents")
            .where("metadata.interviewId", "==", interviewId)
            .get();
            
        const batch = db.batch();
        snapshot.docs.forEach((doc) => batch.delete(doc.ref));
        await batch.commit();
        return;
    }

    const newStatus = newData.status;
    const oldStatus = oldData?.status;
    const newScheduledAt = newData.scheduledAt; // Timestamp
    const oldScheduledAt = oldData?.scheduledAt;

    // Check if we need to sync to calendar
    // Criteria: Status is 'scheduled' AND (Status changed OR Date changed)
    const isScheduled = newStatus === "scheduled";
    const statusChanged = newStatus !== oldStatus;
    const dateChanged = !oldScheduledAt || (newScheduledAt && !newScheduledAt.isEqual(oldScheduledAt));

    if (isScheduled && (statusChanged || dateChanged) && newScheduledAt) {
      functions.logger.info("Syncing interview to calendar", {
        interviewId,
        newStatus,
        date: newScheduledAt.toDate().toISOString(),
        companyUid: newData.companyUid,
        candidateUid: newData.candidateUid
      });

      // Create/Update events
      const companyUid = newData.companyUid;
      const candidateUid = newData.candidateUid;
      
      // We need fetching names? 
      // For MVP, use generic titles or fetch profiles if needed. 
      // Fetching might be slow. Let's use "Entrevista".
      // Or maybe we can't easily get names without expensive reads.
      // Let's rely on generic titles: "Entrevista Programada".

      const date = newScheduledAt; // Timestamp

      const batch = db.batch();

      // Company Event
      const companyEventRef = db.collection("calendarEvents").doc(`int_${interviewId}_comp`);
      batch.set(companyEventRef, {
        title: "Entrevista con Candidato",
        description: `Entrevista programada ID: ${interviewId}`,
        date: date,
        owner_uid: companyUid,
        owner_type: "company",
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        metadata: { interviewId }
      }, { merge: true });

      // Candidate Event
      const candidateEventRef = db.collection("calendarEvents").doc(`int_${interviewId}_cand`);
      batch.set(candidateEventRef, {
        title: "Entrevista con Empresa",
        description: `Entrevista programada ID: ${interviewId}`,
        date: date,
        owner_uid: candidateUid,
        owner_type: "candidate",
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        metadata: { interviewId }
      }, { merge: true });

      await batch.commit();
    } else if (newStatus === "cancelled" && oldStatus !== "cancelled") {
        // Cancelled -> Remove events
        const snapshot = await db.collection("calendarEvents")
            .where("metadata.interviewId", "==", interviewId)
            .get();
            
        const batch = db.batch();
        snapshot.docs.forEach((doc) => batch.delete(doc.ref));
        await batch.commit();
    }
  });
