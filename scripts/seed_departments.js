const admin = require("firebase-admin");

// Check if running against local emulator or cloud
if (process.env.FIRESTORE_EMULATOR_HOST) {
  console.log(`Using Firestore emulator at ${process.env.FIRESTORE_EMULATOR_HOST}`);
  admin.initializeApp({ projectId: "diu-report-box" });
} else {
  // Use service account credentials or default
  admin.initializeApp();
}

const db = admin.firestore();

const departments = [
  {
    id: "swe",
    name: "Software Engineering",
    code: "SWE",
    rooms: [
      { id: "701", roomNo: "701", building: "Main Academic Building", floor: "7th" },
      { id: "702", roomNo: "702", building: "Main Academic Building", floor: "7th" },
      { id: "703", roomNo: "703", building: "Main Academic Building", floor: "7th" },
      { id: "704", roomNo: "704", building: "Main Academic Building", floor: "7th" },
      { id: "705", roomNo: "705", building: "Main Academic Building", floor: "7th" },
      { id: "801", roomNo: "801", building: "Main Academic Building", floor: "8th" },
      { id: "802", roomNo: "802", building: "Main Academic Building", floor: "8th" },
    ],
    maintenanceContacts: [
      {
        id: "swe_maint_1",
        name: "Md. Rafiqul Islam (SWE Lab & Maintenance)",
        phone: "8801712345678",
        active: true,
        categories: ["Computer/IT", "Electrical", "AC/Fan/Light"],
      },
      {
        id: "swe_maint_2",
        name: "Campus Facility Maintenance Team",
        phone: "8801812345678",
        active: true,
        categories: ["Furniture", "Plumbing/Washroom", "Cleaning", "Other"],
      },
    ],
  },
  {
    id: "cse",
    name: "Computer Science & Engineering",
    code: "CSE",
    rooms: [
      { id: "501", roomNo: "501", building: "Engineering Building", floor: "5th" },
      { id: "502", roomNo: "502", building: "Engineering Building", floor: "5th" },
      { id: "503", roomNo: "503", building: "Engineering Building", floor: "5th" },
      { id: "601", roomNo: "601", building: "Engineering Building", floor: "6th" },
      { id: "602", roomNo: "602", building: "Engineering Building", floor: "6th" },
    ],
    maintenanceContacts: [
      {
        id: "cse_maint_1",
        name: "CSE Lab Support Staff",
        phone: "8801912345678",
        active: true,
        categories: [], // Receives all categories
      },
    ],
  },
  {
    id: "eee",
    name: "Electrical & Electronic Engineering",
    code: "EEE",
    rooms: [
      { id: "301", roomNo: "301", building: "Engineering Building", floor: "3rd" },
      { id: "302", roomNo: "302", building: "Engineering Building", floor: "3rd" },
      { id: "401", roomNo: "401", building: "Engineering Building", floor: "4th" },
    ],
    maintenanceContacts: [
      {
        id: "eee_maint_1",
        name: "EEE Workshop In-charge",
        phone: "8801612345678",
        active: true,
      },
    ],
  },
  {
    id: "bba",
    name: "Business Administration",
    code: "BBA",
    rooms: [
      { id: "201", roomNo: "201", building: "Faculty of Business Studies", floor: "2nd" },
      { id: "202", roomNo: "202", building: "Faculty of Business Studies", floor: "2nd" },
      { id: "305", roomNo: "305", building: "Faculty of Business Studies", floor: "3rd" },
    ],
    maintenanceContacts: [
      {
        id: "bba_maint_1",
        name: "BBA Maintenance Desk",
        phone: "8801512345678",
        active: true,
      },
    ],
  },
  {
    id: "civil",
    name: "Civil Engineering",
    code: "CE",
    rooms: [
      { id: "101", roomNo: "101", building: "Engineering Building", floor: "1st" },
      { id: "102", roomNo: "102", building: "Engineering Building", floor: "1st" },
    ],
    maintenanceContacts: [
      {
        id: "ce_maint_1",
        name: "Civil Dept Maintenance",
        phone: "8801312345678",
        active: true,
      },
    ],
  },
];

async function seed() {
  console.log("Seeding departments, rooms, and maintenance contacts...");
  for (const dept of departments) {
    const deptRef = db.collection("departments").doc(dept.id);
    await deptRef.set({
      name: dept.name,
      code: dept.code,
    });
    console.log(`- Department: ${dept.name} (${dept.code})`);

    for (const room of dept.rooms) {
      await deptRef.collection("rooms").doc(room.id).set({
        roomNo: room.roomNo,
        building: room.building,
        floor: room.floor,
      });
    }
    console.log(`  Added ${dept.rooms.length} rooms`);

    for (const contact of dept.maintenanceContacts) {
      await deptRef.collection("maintenanceContacts").doc(contact.id).set(contact);
    }
    console.log(`  Added ${dept.maintenanceContacts.length} maintenance contacts`);
  }

  // Initialize report counter if not present
  const counterRef = db.collection("metadata").doc("reportCounter");
  const counterSnap = await counterRef.get();
  if (!counterSnap.exists) {
    await counterRef.set({ current: 1000 });
    console.log("Initialized metadata/reportCounter to 1000");
  }

  console.log("Seeding complete!");
}

seed().catch(console.error);
