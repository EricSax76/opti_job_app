
import * as admin from "firebase-admin";

// Initialize Admin SDK
// Usage: ts-node scripts/backfillInterviews.ts
if (admin.apps.length === 0) {
    admin.initializeApp();
}

const db = admin.firestore();

async function backfillInterviews() {
    console.log("Starting backfill for missing interviews...");

    const applicationsSnap = await db.collection("applications")
        .where("status", "==", "interview")
        .get();

    if (applicationsSnap.empty) {
        console.log("No applications in 'interview' status found.");
        return;
    }

    console.log(`Found ${applicationsSnap.size} applications in 'interview' status.`);

    let createdCount = 0;
    let skippedCount = 0;
    let errorCount = 0;

    const batchSize = 100;
    let batch = db.batch();
    let opCount = 0;

    for (const appDoc of applicationsSnap.docs) {
        const appId = appDoc.id;
        const appData = appDoc.data();
        
        // Check if interview doc exists with same ID
        const interviewRef = db.collection("interviews").doc(appId);
        const interviewSnap = await interviewRef.get();

        if (interviewSnap.exists) {
            skippedCount++;
            continue;
        }

        // Need to fetch job offer to get companyUid if not present in application
        // Assuming application has companyId or jobOfferId
        const jobOfferId = appData.jobOfferId;
        const candidateUid = appData.candidateUid;
        
        if (!jobOfferId || !candidateUid) {
            console.error(`Skipping app ${appId}: Missing jobOfferId or candidateUid`);
            errorCount++;
            continue;
        }

        try {
            // We might need companyUid. Often it's in the job offer.
            // For bulk script, we can do a read.
            const jobDoc = await db.collection("job_offers").doc(jobOfferId).get();
            if (!jobDoc.exists) {
                console.error(`Skipping app ${appId}: Job offer ${jobOfferId} not found`);
                errorCount++;
                continue;
            }
            
            const companyUid = jobDoc.data()?.companyUid; // Adjust field name if needed
             if (!companyUid) {
                console.error(`Skipping app ${appId}: companyUid not found in job offer`);
                errorCount++;
                continue;
            }

            // Create Interview Doc
            const interviewData = {
                id: appId,
                applicationId: appId,
                jobOfferId: jobOfferId,
                companyUid: companyUid,
                candidateUid: candidateUid,
                participants: [companyUid, candidateUid],
                status: "scheduling", // Default to scheduling if just backfilling
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
                // Add initial system message if desired, or skip
            };

            batch.set(interviewRef, interviewData);
            createdCount++;
            opCount++;

            if (opCount >= batchSize) {
                await batch.commit();
                batch = db.batch();
                opCount = 0;
                console.log(`Committed batch. Total created so far: ${createdCount}`);
            }

        } catch (e) {
            console.error(`Error processing app ${appId}:`, e);
            errorCount++;
        }
    }

    if (opCount > 0) {
        await batch.commit();
    }

    console.log("Backfill complete.");
    console.log(`Created: ${createdCount}`);
    console.log(`Skipped (already existed): ${skippedCount}`);
    console.log(`Errors: ${errorCount}`);
}

backfillInterviews().catch(console.error);
