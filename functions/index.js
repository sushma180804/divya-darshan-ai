// functions/index.js

const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

/**
 * This Cloud Function runs automatically every day at midnight.
 * It queries the 'bookings' collection for all documents where the
 * darshanDate is in the past and deletes them in a batch.
 */
exports.deleteOldBookings = functions.pubsub
  // Schedule to run every 24 hours. You can also use cron syntax.
  // e.g., '0 0 * * *' runs at midnight every day.
  .schedule("every 24 hours")
  .onRun(async (context) => {
    const db = admin.firestore();
    const now = new Date();

    // Query for all bookings with a darshanDate before the start of today.
    const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const oldBookingsQuery = db
      .collection("bookings")
      .where("darshanDate", "<", startOfToday);

    const snapshot = await oldBookingsQuery.get();

    // If there are no old bookings, do nothing.
    if (snapshot.empty) {
      console.log("No old bookings to delete.");
      return null;
    }

    // Create a batch to delete all old documents at once.
    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    // Commit the batch.
    await batch.commit();

    console.log(`Successfully deleted ${snapshot.size} old bookings.`);
    return null;
  });