const fs = require("fs");
const os = require("os");
const path = require("path");

const PROJECT_ID = "fast-must-orientation";
const FIREBASE_CLIENT_ID =
  "563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com";
const FIREBASE_CLIENT_SECRET = "j9iVZfS8kkCEFUPaAeJV0sAi";
const FIRESTORE_BASE_URL =
  `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;

const args = new Set(process.argv.slice(2));
const dryRun = args.has("--dry-run");
const seedExamples = !args.has("--no-examples");
const shouldSeedQuickLinks = !args.has("--no-quick-links");

function log(message = "") {
  console.log(message);
}

function getFirebaseToolsConfigPath() {
  return path.join(
      os.homedir(),
      ".config",
      "configstore",
      "firebase-tools.json",
  );
}

function loadRefreshTokenCredential() {
  const configPath = getFirebaseToolsConfigPath();
  if (!fs.existsSync(configPath)) {
    throw new Error(
        `Firebase CLI config not found at ${configPath}. ` +
        "Run `firebase login` first.",
    );
  }

  const raw = fs.readFileSync(configPath, "utf8");
  const config = JSON.parse(raw);
  const refreshToken = config?.tokens?.refresh_token;

  if (!refreshToken) {
    throw new Error(
        "No Firebase CLI refresh token found. Run `firebase login` first.",
    );
  }

  return {
    clientId: FIREBASE_CLIENT_ID,
    clientSecret: FIREBASE_CLIENT_SECRET,
    refreshToken,
  };
}

async function getAccessToken() {
  const credential = loadRefreshTokenCredential();
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: new URLSearchParams({
      client_id: credential.clientId,
      client_secret: credential.clientSecret,
      refresh_token: credential.refreshToken,
      grant_type: "refresh_token",
    }),
  });

  if (!response.ok) {
    throw new Error(
        `Failed to refresh Firebase CLI access token: ${response.status} ${await response.text()}`,
    );
  }

  const data = await response.json();
  if (!data.access_token) {
    throw new Error("OAuth token refresh succeeded but no access token was returned.");
  }

  return data.access_token;
}

async function initializeFirestore() {
  const accessToken = await getAccessToken();
  return new FirestoreRestClient({
    projectId: PROJECT_ID,
    accessToken,
  });
}

function timestamp(date = new Date()) {
  return date instanceof Date ? date : new Date(date);
}

function slugify(value) {
  return value.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "");
}

function buildShortName(name) {
  const words = String(name).split(/\s+/).filter(Boolean);
  if (words.length <= 1) {
    return name;
  }
  return words
      .filter((word, index) =>
        word.length > 2 || index === 0 || index === words.length - 1)
      .map((word) => word[0].toUpperCase())
      .join("");
}

function buildShortDescription(description, name) {
  if (!description) {
    return `Learn more about ${name} at FAST.`;
  }
  if (description.length <= 140) {
    return description;
  }
  return `${description.slice(0, 137).trim()}...`;
}

function readString(data, key) {
  const value = data?.[key];
  if (typeof value !== "string") {
    return null;
  }
  const trimmed = value.trim();
  return trimmed || null;
}

function readInt(data, key) {
  const value = data?.[key];
  if (typeof value === "number") {
    return Math.trunc(value);
  }
  if (typeof value === "string") {
    const parsed = parseInt(value.trim(), 10);
    return Number.isNaN(parsed) ? null : parsed;
  }
  return null;
}

function readBool(data, key) {
  const value = data?.[key];
  return typeof value === "boolean" ? value : null;
}

function readStringList(data, key, fallback = []) {
  const value = data?.[key];
  if (!Array.isArray(value)) {
    return [...fallback];
  }
  const normalized = value
      .map((item) => String(item ?? "").trim())
      .filter(Boolean);
  return normalized.length ? normalized : [...fallback];
}

function readMap(data, key) {
  const value = data?.[key];
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return null;
  }
  return {...value};
}

function inferRoleType(position) {
  const normalized = String(position || "").toLowerCase();
  if (normalized.includes("dean")) {
    return "dean";
  }
  if (normalized.includes("head")) {
    return "hod";
  }
  if (
    normalized.includes("contact") ||
    normalized.includes("support") ||
    normalized.includes("administrator")
  ) {
    return "key_contact";
  }
  return "staff";
}

function inferAward(programName) {
  const normalized = String(programName || "").toLowerCase();
  if (normalized.includes("master")) {
    return "Master";
  }
  if (normalized.includes("phd") || normalized.includes("doctor")) {
    return "Doctorate";
  }
  if (normalized.includes("diploma")) {
    return "Diploma";
  }
  if (normalized.includes("certificate")) {
    return "Certificate";
  }
  return "Bachelor";
}

function inferAnnouncementType(data) {
  const category = String(readString(data, "category") || "").toLowerCase();
  const title = String(readString(data, "title") || "").toLowerCase();
  const description = String(readString(data, "description") || "").toLowerCase();

  if (
    category.includes("event") ||
    title.includes("event") ||
    title.includes("summit") ||
    title.includes("fair") ||
    title.includes("ceremony")
  ) {
    return "event";
  }

  if (
    category.includes("deadline") ||
    title.includes("deadline") ||
    description.includes("deadline")
  ) {
    return "deadline";
  }

  if (
    title.includes("opportunit") ||
    title.includes("scholarship") ||
    title.includes("research")
  ) {
    return "opportunity";
  }

  return "announcement";
}

function parseYearFromId(id) {
  const match = String(id).match(/(\d+)/);
  return match ? parseInt(match[1], 10) : 1;
}

function normalizeCourses(rawCourses) {
  if (!Array.isArray(rawCourses)) {
    return [];
  }

  return rawCourses
      .filter((course) => course && typeof course === "object")
      .map((course) => {
        const normalized = {
          code: readString(course, "code") || "",
          name: readString(course, "name") || "",
          description: readString(course, "description") || "",
          credits: readInt(course, "credits") || 0,
        };

        if (course.semester !== undefined && course.semester !== null) {
          normalized.semester = readInt(course, "semester") || course.semester;
        }

        return normalized;
      });
}

class FirestoreRestClient {
  constructor({projectId, accessToken}) {
    this.projectId = projectId;
    this.accessToken = accessToken;
  }

  collection(collectionPath) {
    return new CollectionReference(this, collectionPath);
  }

  async request(method, resourcePath, {body, mask} = {}) {
    const encodedPath = encodeFirestorePath(resourcePath);
    let url = `${FIRESTORE_BASE_URL}/${encodedPath}`;

    if (mask && mask.length) {
      const params = new URLSearchParams();
      for (const field of mask) {
        params.append("updateMask.fieldPaths", field);
      }
      url += `?${params.toString()}`;
    }

    const response = await fetch(url, {
      method,
      headers: {
        Authorization: `Bearer ${this.accessToken}`,
        "Content-Type": "application/json",
      },
      body: body ? JSON.stringify(body) : undefined,
    });

    if (response.status === 404) {
      return {status: 404, data: null};
    }

    if (!response.ok) {
      throw new Error(
          `Firestore REST request failed (${method} ${resourcePath}): ` +
          `${response.status} ${await response.text()}`,
      );
    }

    return {
      status: response.status,
      data: await response.json(),
    };
  }
}

class CollectionReference {
  constructor(client, collectionPath) {
    this.client = client;
    this.path = collectionPath;
  }

  doc(id) {
    return new DocumentReference(this.client, `${this.path}/${id}`);
  }

  async get() {
    const response = await this.client.request("GET", this.path);
    const documents = (response.data && response.data.documents) || [];
    const docs = documents.map((document) => {
      const ref = new DocumentReference(this.client, toRelativePath(document.name));
      return new DocumentSnapshot({
        id: ref.id,
        ref,
        fields: decodeFields(document.fields || {}),
        exists: true,
      });
    });

    return {
      docs,
      empty: docs.length === 0,
    };
  }
}

class DocumentReference {
  constructor(client, documentPath) {
    this.client = client;
    this.path = documentPath;
    this.id = documentPath.split("/").pop();
  }

  collection(collectionName) {
    return new CollectionReference(this.client, `${this.path}/${collectionName}`);
  }

  async get() {
    const response = await this.client.request("GET", this.path);
    if (response.status === 404) {
      return new DocumentSnapshot({
        id: this.id,
        ref: this,
        fields: {},
        exists: false,
      });
    }

    return new DocumentSnapshot({
      id: this.id,
      ref: this,
      fields: decodeFields(response.data.fields || {}),
      exists: true,
    });
  }

  async set(data, options = {}) {
    const fields = encodeFields(data);
    const mask = options.merge ? Object.keys(data) : undefined;
    await this.client.request("PATCH", this.path, {
      body: {fields},
      mask,
    });
  }
}

class DocumentSnapshot {
  constructor({id, ref, fields, exists}) {
    this.id = id;
    this.ref = ref;
    this._fields = fields;
    this.exists = exists;
  }

  data() {
    return {...this._fields};
  }
}

function encodeFirestorePath(resourcePath) {
  return resourcePath.split("/").map(encodeURIComponent).join("/");
}

function toRelativePath(fullResourceName) {
  const marker = "/documents/";
  const index = fullResourceName.indexOf(marker);
  return index === -1 ?
    fullResourceName :
    fullResourceName.slice(index + marker.length);
}

function encodeFields(data) {
  const fields = {};
  for (const [key, value] of Object.entries(data)) {
    fields[key] = encodeValue(value);
  }
  return fields;
}

function encodeValue(value) {
  if (value === null || value === undefined) {
    return {nullValue: null};
  }

  if (value instanceof Date) {
    return {timestampValue: value.toISOString()};
  }

  if (typeof value === "string") {
    return {stringValue: value};
  }

  if (typeof value === "boolean") {
    return {booleanValue: value};
  }

  if (typeof value === "number") {
    if (Number.isInteger(value)) {
      return {integerValue: String(value)};
    }
    return {doubleValue: value};
  }

  if (Array.isArray(value)) {
    return {
      arrayValue: {
        values: value.map((item) => encodeValue(item)),
      },
    };
  }

  if (typeof value === "object") {
    return {
      mapValue: {
        fields: encodeFields(value),
      },
    };
  }

  return {stringValue: String(value)};
}

function decodeFields(fields) {
  const result = {};
  for (const [key, value] of Object.entries(fields)) {
    result[key] = decodeValue(value);
  }
  return result;
}

function decodeValue(value) {
  if (Object.prototype.hasOwnProperty.call(value, "stringValue")) {
    return value.stringValue;
  }
  if (Object.prototype.hasOwnProperty.call(value, "integerValue")) {
    return parseInt(value.integerValue, 10);
  }
  if (Object.prototype.hasOwnProperty.call(value, "doubleValue")) {
    return value.doubleValue;
  }
  if (Object.prototype.hasOwnProperty.call(value, "booleanValue")) {
    return value.booleanValue;
  }
  if (Object.prototype.hasOwnProperty.call(value, "timestampValue")) {
    return new Date(value.timestampValue);
  }
  if (Object.prototype.hasOwnProperty.call(value, "nullValue")) {
    return null;
  }
  if (Object.prototype.hasOwnProperty.call(value, "arrayValue")) {
    const values = value.arrayValue.values || [];
    return values.map((item) => decodeValue(item));
  }
  if (Object.prototype.hasOwnProperty.call(value, "mapValue")) {
    return decodeFields(value.mapValue.fields || {});
  }
  return null;
}

function sampleDepartments() {
  const now = timestamp();
  return [
    {
      id: "1",
      data: {
        id: "1",
        name: "Electrical and Electronics Engineering",
        shortName: "EEE",
        slug: "electrical-and-electronics-engineering",
        description:
          "The department focuses on electrical systems, electronics, energy, automation, and innovation in engineering practice.",
        shortDescription:
          "Explore electrical systems, electronics, energy, and automation.",
        imageUrl: "",
        headName: "Head of Department",
        headTitle: "Head of Department",
        headImageUrl: "",
        headMessage:
          "Welcome to a department committed to practical engineering, innovation, and student growth.",
        contactEmail: "",
        contactPhone: "",
        location: "",
        featured: true,
        order: 1,
        facilities: ["Electrical Machines Lab", "Electronics Lab"],
        achievements: ["Student innovation showcases"],
        status: "published",
        createdAt: now,
        updatedAt: now,
      },
      programs: [
        {
          id: "bachelor-electrical-and-electronics-engineering",
          data: {
            name: "Bachelor of Electrical and Electronics Engineering",
            award: "Bachelor",
            slug: "bachelor-of-electrical-and-electronics-engineering",
            summary:
              "A professional programme focused on electrical systems, power, electronics, and communication engineering.",
            durationYears: 4,
            studyMode: "full-time",
            intake: ["August"],
            entryRequirements: "",
            careerPaths: ["Power systems", "Telecommunications"],
            brochureUrl: "",
            featured: true,
            order: 1,
            status: "published",
            createdAt: now,
            updatedAt: now,
          },
          yearCourses: [
            {
              id: "year1",
              data: {
                year: 1,
                courses: [
                  {
                    code: "EEE101",
                    name: "Introduction to Electrical Engineering",
                    description:
                      "A foundation course introducing core principles and concepts in electrical engineering.",
                    credits: 3,
                  },
                  {
                    code: "MTH101",
                    name: "Engineering Mathematics I",
                    description:
                      "Mathematics tools used across engineering disciplines.",
                    credits: 4,
                  },
                ],
                updatedAt: now,
              },
            },
          ],
        },
      ],
    },
    {
      id: "2",
      data: {
        id: "2",
        name: "Computer Science and Information Technology",
        shortName: "CSIT",
        slug: "computer-science-and-information-technology",
        description:
          "The department covers software development, networking, data systems, and digital innovation.",
        shortDescription:
          "Study software, systems, networking, and digital innovation.",
        imageUrl: "",
        headName: "Head of Department",
        headTitle: "Head of Department",
        headImageUrl: "",
        headMessage:
          "Discover a department shaping digital solutions, innovation, and future-ready graduates.",
        contactEmail: "",
        contactPhone: "",
        location: "",
        featured: true,
        order: 2,
        facilities: ["Programming Lab", "Networking Lab"],
        achievements: ["Student software exhibitions"],
        status: "published",
        createdAt: now,
        updatedAt: now,
      },
      programs: [
        {
          id: "bachelor-computer-science",
          data: {
            name: "Bachelor of Computer Science",
            award: "Bachelor",
            slug: "bachelor-of-computer-science",
            summary:
              "A programme focused on computing theory, software engineering, data, and modern digital systems.",
            durationYears: 3,
            studyMode: "full-time",
            intake: ["August"],
            entryRequirements: "",
            careerPaths: ["Software engineering", "Data systems"],
            brochureUrl: "",
            featured: true,
            order: 1,
            status: "published",
            createdAt: now,
            updatedAt: now,
          },
          yearCourses: [
            {
              id: "year1",
              data: {
                year: 1,
                courses: [
                  {
                    code: "CSC101",
                    name: "Introduction to Programming",
                    description:
                      "Foundational programming concepts and problem-solving.",
                    credits: 4,
                  },
                  {
                    code: "CSC102",
                    name: "Computer Systems Fundamentals",
                    description:
                      "An introduction to how computer systems and software platforms work.",
                    credits: 3,
                  },
                ],
                updatedAt: now,
              },
            },
          ],
        },
      ],
    },
  ];
}

function sampleStaff() {
  const now = timestamp();
  return [
    {
      id: "deans1",
      data: {
        name: "Dean, FAST",
        position: "Dean",
        roleType: "dean",
        department: "",
        departmentName: "",
        email: "",
        phone: "",
        office: "",
        linkedinUrl: "",
        photoUrl: "",
        bio:
          "Faculty leadership profile for the Dean of the Faculty of Applied Sciences and Technology.",
        specialties: [],
        isKeyContact: true,
        featured: true,
        order: 1,
        status: "published",
        createdAt: now,
        updatedAt: now,
      },
    },
    {
      id: "student-support-1",
      data: {
        name: "Student Support Officer",
        position: "Student Support Officer",
        roleType: "key_contact",
        department: "",
        departmentName: "",
        email: "",
        phone: "",
        office: "",
        linkedinUrl: "",
        photoUrl: "",
        bio: "A key FAST contact for student guidance, support, and referrals.",
        specialties: ["Student guidance", "Support referrals"],
        isKeyContact: true,
        featured: true,
        order: 2,
        status: "published",
        createdAt: now,
        updatedAt: now,
      },
    },
  ];
}

function sampleAnnouncements() {
  const now = new Date();
  return [
    {
      id: "welcome-fast-connect",
      data: {
        title: "Welcome to FAST Connect",
        description:
          "FAST Connect now brings together faculty visibility, updates, discovery, and student support in one place.",
        category: "General",
        type: "announcement",
        priority: "important",
        isPinned: true,
        featured: true,
        imageUrls: [],
        tags: ["welcome", "fast-connect", "faculty-platform"],
        views: 0,
        audience: ["all-users"],
        departmentIds: [],
        status: "published",
        postedAt: timestamp(now),
        createdAt: timestamp(now),
        updatedAt: timestamp(now),
      },
    },
    {
      id: "research-opportunity-call",
      data: {
        title: "Research Opportunity Call",
        description:
          "Students are invited to explore new research opportunities across FAST departments and labs.",
        category: "Academic",
        type: "opportunity",
        priority: "normal",
        isPinned: false,
        featured: false,
        imageUrls: [],
        tags: ["research", "opportunity"],
        views: 0,
        audience: ["students"],
        departmentIds: [],
        status: "published",
        postedAt: timestamp(new Date(now.getTime() - 2 * 24 * 60 * 60 * 1000)),
        createdAt: timestamp(new Date(now.getTime() - 2 * 24 * 60 * 60 * 1000)),
        updatedAt: timestamp(now),
      },
    },
  ];
}

async function setDocument(ref, data) {
  if (dryRun) {
    log(`DRY RUN -> ${ref.path}`);
    return;
  }
  await ref.set(data, {merge: true});
}

async function seedOrMigrateDepartments(db) {
  log("Checking departments...");
  const snapshot = await db.collection("departments").get();

  if (snapshot.empty) {
    if (!seedExamples) {
      log("No departments found. Example department data seeding is disabled.");
      return;
    }

    for (const department of sampleDepartments()) {
      const departmentRef = db.collection("departments").doc(department.id);
      await setDocument(departmentRef, department.data);
      log(`Prepared department ${department.id}`);

      for (const program of department.programs) {
        const programRef = departmentRef.collection("programs").doc(program.id);
        await setDocument(programRef, program.data);

        for (const yearCourse of program.yearCourses) {
          await setDocument(
              programRef.collection("yearCourses").doc(yearCourse.id),
              yearCourse.data,
          );
        }
      }
    }

    log("Seeded example departments, programs, and year courses.");
    return;
  }

  let order = 1;
  for (const doc of snapshot.docs) {
    const data = doc.data();
    const name = readString(data, "name") || `Department ${doc.id}`;
    const description = readString(data, "description") || "";

    await setDocument(doc.ref, {
      id: readString(data, "id") || doc.id,
      name,
      shortName: readString(data, "shortName") || buildShortName(name),
      slug: readString(data, "slug") || slugify(name),
      description,
      shortDescription:
        readString(data, "shortDescription") ||
        buildShortDescription(description, name),
      imageUrl: readString(data, "imageUrl") || "",
      headName: readString(data, "headName") || "",
      headTitle: readString(data, "headTitle") || "Head of Department",
      headImageUrl: readString(data, "headImageUrl") || "",
      headMessage: readString(data, "headMessage") || "",
      contactEmail: readString(data, "contactEmail") || "",
      contactPhone: readString(data, "contactPhone") || "",
      location: readString(data, "location") || "",
      featured: readBool(data, "featured") ?? order === 1,
      order: readInt(data, "order") || order,
      facilities: readStringList(data, "facilities"),
      achievements: readStringList(data, "achievements"),
      status: readString(data, "status") || "published",
      createdAt: data.createdAt || timestamp(),
      updatedAt: timestamp(),
    });

    await migratePrograms(doc.ref);
    order += 1;
  }

  log(`Migrated ${snapshot.docs.length} department documents.`);
}

async function migratePrograms(departmentRef) {
  const snapshot = await departmentRef.collection("programs").get();
  let order = 1;

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const name = readString(data, "name") || "Unnamed Program";

    await setDocument(doc.ref, {
      name,
      award: readString(data, "award") || inferAward(name),
      slug: readString(data, "slug") || slugify(name),
      summary:
        readString(data, "summary") || `Learn more about ${name} at FAST.`,
      durationYears: readInt(data, "durationYears") || 4,
      studyMode: readString(data, "studyMode") || "full-time",
      intake: readStringList(data, "intake"),
      entryRequirements: readString(data, "entryRequirements") || "",
      careerPaths: readStringList(data, "careerPaths"),
      brochureUrl: readString(data, "brochureUrl") || "",
      featured: readBool(data, "featured") ?? order === 1,
      order: readInt(data, "order") || order,
      status: readString(data, "status") || "published",
      createdAt: data.createdAt || timestamp(),
      updatedAt: timestamp(),
    });

    await migrateYearCourses(doc.ref);
    order += 1;
  }
}

async function migrateYearCourses(programRef) {
  const snapshot = await programRef.collection("yearCourses").get();

  for (const doc of snapshot.docs) {
    const data = doc.data();
    await setDocument(doc.ref, {
      year: readInt(data, "year") || parseYearFromId(doc.id),
      courses: normalizeCourses(data.courses),
      updatedAt: timestamp(),
    });
  }
}

async function seedOrMigrateStaff(db) {
  log("Checking staff...");
  const snapshot = await db.collection("staff").get();

  if (snapshot.empty) {
    if (!seedExamples) {
      log("No staff found. Example staff seeding is disabled.");
      return;
    }

    for (const member of sampleStaff()) {
      await setDocument(db.collection("staff").doc(member.id), member.data);
    }

    log("Seeded example staff records.");
    return;
  }

  let order = 1;
  for (const doc of snapshot.docs) {
    const data = doc.data();
    const position = readString(data, "position") || "";
    const roleType = readString(data, "roleType") || inferRoleType(position);
    const payload = {
      name: readString(data, "name") || "Unnamed Staff Member",
      position,
      roleType,
      department: readString(data, "department") || "",
      departmentName:
        readString(data, "departmentName") ||
        readString(data, "department") ||
        "",
      email: readString(data, "email") || "",
      phone: readString(data, "phone") || "",
      office: readString(data, "office") || "",
      linkedinUrl: readString(data, "linkedinUrl") || "",
      photoUrl: readString(data, "photoUrl") || "",
      bio: readString(data, "bio") || "",
      specialties: readStringList(data, "specialties"),
      isKeyContact:
        readBool(data, "isKeyContact") ??
        (roleType === "dean" ||
          roleType === "hod" ||
          roleType === "key_contact"),
      featured:
        readBool(data, "featured") ??
        (roleType === "dean" || roleType === "hod"),
      order: readInt(data, "order") || order,
      status: readString(data, "status") || "published",
      createdAt: data.createdAt || timestamp(),
      updatedAt: timestamp(),
    };

    const departmentId = readString(data, "departmentId");
    if (departmentId) {
      payload.departmentId = departmentId;
    }

    await setDocument(doc.ref, payload);
    order += 1;
  }

  log(`Migrated ${snapshot.docs.length} staff documents.`);
}

async function seedOrMigrateAnnouncements(db) {
  log("Checking announcements...");
  const snapshot = await db.collection("announcements").get();

  if (snapshot.empty) {
    if (!seedExamples) {
      log("No announcements found. Example announcement seeding is disabled.");
      return;
    }

    for (const announcement of sampleAnnouncements()) {
      await setDocument(
          db.collection("announcements").doc(announcement.id),
          announcement.data,
      );
    }

    log("Seeded example announcements.");
    return;
  }

  for (const doc of snapshot.docs) {
    const data = doc.data();
    const postedAt = data.postedAt || timestamp();
    const payload = {
      title: readString(data, "title") || "Untitled Update",
      description: readString(data, "description") || "",
      category: readString(data, "category") || "General",
      type: readString(data, "type") || inferAnnouncementType(data),
      priority: readString(data, "priority") || "normal",
      isPinned: readBool(data, "isPinned") || false,
      featured:
        (readBool(data, "featured") ?? readBool(data, "isPinned")) || false,
      imageUrls: readStringList(data, "imageUrls"),
      tags: readStringList(data, "tags"),
      views: readInt(data, "views") || 0,
      audience: readStringList(data, "audience", ["all-users"]),
      departmentIds: readStringList(data, "departmentIds"),
      status: readString(data, "status") || "published",
      postedAt,
      createdAt: data.createdAt || postedAt,
      updatedAt: timestamp(),
    };

    const ctaLabel = readString(data, "ctaLabel");
    const ctaUrl = readString(data, "ctaUrl");
    if (ctaLabel) {
      payload.ctaLabel = ctaLabel;
    }
    if (ctaUrl) {
      payload.ctaUrl = ctaUrl;
    }
    if (data.startDate) {
      payload.startDate = data.startDate;
    }
    if (data.endDate) {
      payload.endDate = data.endDate;
    }

    await setDocument(doc.ref, payload);
  }

  log(`Migrated ${snapshot.docs.length} announcement documents.`);
}

async function seedFacultyInfo(db) {
  log("Preparing faculty_info/fast...");
  const departmentsSnapshot = await db.collection("departments").get();
  const staffSnapshot = await db.collection("staff").get();

  let programCount = 0;
  for (const department of departmentsSnapshot.docs) {
    const programs = await department.ref.collection("programs").get();
    programCount += programs.docs.length;
  }

  let dean = null;
  for (const doc of staffSnapshot.docs) {
    const data = doc.data();
    const roleType = readString(data, "roleType") || "";
    const position = readString(data, "position") || "";
    if (roleType === "dean" || position.toLowerCase().includes("dean")) {
      dean = doc;
      break;
    }
  }

  const deanData = dean ? dean.data() : {};
  const facultyRef = db.collection("faculty_info").doc("fast");
  const facultySnapshot = await facultyRef.get();
  const data = facultySnapshot.exists ? facultySnapshot.data() : {};

  const deanName =
    readString(data, "deanName") ||
    readString(data, "dean_name") ||
    readString(deanData, "name") ||
    "Dean, FAST";
  const deanMessage =
    readString(data, "deanMessage") ||
    readString(data, "dean_message") ||
    "Welcome to FAST. Discover our departments, people, achievements, and opportunities through one connected faculty platform.";
  const deanPhotoUrl =
    readString(data, "deanPhotoUrl") ||
    readString(data, "dean_photo_url") ||
    readString(deanData, "photoUrl") ||
    "";
  const heroImageUrl =
    readString(data, "heroImageUrl") ||
    readString(data, "faculty_image_url") ||
    "";
  const vision =
    readString(data, "vision") ||
    readString(data, "faculty_vision") ||
    "To be a leading faculty in applied sciences, technology, innovation, and student success.";
  const mission =
    readString(data, "mission") ||
    readString(data, "faculty_mission") ||
    "To provide transformative education, research, innovation, and community engagement in science and technology.";

  await setDocument(facultyRef, {
    name: readString(data, "name") || "Faculty of Applied Sciences and Technology",
    shortName: readString(data, "shortName") || "FAST",
    appName: readString(data, "appName") || "FAST Connect",
    heroTitle: readString(data, "heroTitle") || "Explore FAST",
    heroSubtitle:
      readString(data, "heroSubtitle") ||
      "A faculty platform for branding, discovery, updates, and student support.",
    heroImageUrl,
    overview:
      readString(data, "overview") ||
      "FAST brings together departments, people, programs, stories, and support resources in one experience.",
    vision,
    mission,
    stats: [
      {label: "Departments", value: departmentsSnapshot.docs.length},
      {label: "Programs", value: programCount},
      {label: "Staff", value: staffSnapshot.docs.length},
    ],
    deanId: readString(data, "deanId") || (dean && dean.id) || "deans1",
    deanName,
    deanMessage,
    deanPhotoUrl,
    contactEmail: readString(data, "contactEmail") || "",
    contactPhone: readString(data, "contactPhone") || "",
    websiteUrl: readString(data, "websiteUrl") || "",
    socialLinks: readMap(data, "socialLinks") || {
      facebook: "",
      linkedin: "",
      youtube: "",
    },
    createdAt: data.createdAt || timestamp(),
    updatedAt: timestamp(),
    dean_name: deanName,
    dean_message: deanMessage,
    dean_photo_url: deanPhotoUrl,
    faculty_image_url: heroImageUrl,
    faculty_vision: vision,
    faculty_mission: mission,
    faculty_values: readStringList(data, "faculty_values", [
      "Excellence in teaching and learning",
      "Research and innovation",
      "Integrity and accountability",
      "Collaboration and community impact",
    ]),
  });

  log("Upserted faculty_info/fast.");
}

async function seedSimpleCollection(db, collectionName, documents) {
  const collection = db.collection(collectionName);
  for (const document of documents) {
    await setDocument(collection.doc(document.id), document.data);
  }
}

async function seedFeaturedStories(db) {
  log("Seeding featured_stories...");
  await seedSimpleCollection(db, "featured_stories", [
    {
      id: "fast-featured-story",
      data: {
        title: "FAST Connect expands into a full faculty platform",
        summary:
          "FAST Connect now brings together faculty updates, people, departments, opportunities, and student support in one place.",
        content:
          "The FAST platform is evolving from a first-year orientation app into a broader faculty experience that supports visibility, communication, discovery, and student success.",
        imageUrl: "",
        authorName: "FAST Communications Team",
        departmentIds: [],
        personIds: [],
        publishedAt: timestamp(),
        featured: true,
        order: 1,
        status: "published",
        createdAt: timestamp(),
        updatedAt: timestamp(),
      },
    },
  ]);
}

async function seedOrientationContent(db) {
  log("Seeding orientation_content...");
  await seedSimpleCollection(db, "orientation_content", [
    {
      id: "first-year-orientation-guide",
      data: {
        title: "First-Year Orientation Guide",
        slug: "first-year-orientation-guide",
        category: "orientation",
        summary: "A practical starting point for new students joining FAST.",
        content:
          "Use this guide to understand registration, academic expectations, support contacts, and life at FAST during your first weeks on campus.",
        audience: ["first-year", "students"],
        order: 1,
        status: "published",
        createdAt: timestamp(),
        updatedAt: timestamp(),
      },
    },
    {
      id: "student-success-basics",
      data: {
        title: "Student Success Basics",
        slug: "student-success-basics",
        category: "student-support",
        summary:
          "Core academic and campus habits that help continuing and new students succeed.",
        content:
          "Stay connected to updates, attend classes consistently, use support resources early, and build a relationship with your department and lecturers.",
        audience: ["students"],
        order: 2,
        status: "published",
        createdAt: timestamp(),
        updatedAt: timestamp(),
      },
    },
  ]);
}

async function seedSupportResources(db) {
  log("Seeding support_resources...");
  await seedSimpleCollection(db, "support_resources", [
    {
      id: "academic-support",
      data: {
        title: "Academic Support",
        category: "academic",
        description:
          "Support for registration questions, course guidance, and academic concerns.",
        contactEmail: "",
        contactPhone: "",
        location: "",
        url: "",
        audience: ["students"],
        order: 1,
        status: "published",
        createdAt: timestamp(),
        updatedAt: timestamp(),
      },
    },
    {
      id: "student-wellbeing",
      data: {
        title: "Student Wellbeing",
        category: "wellbeing",
        description:
          "Guidance, welfare, and student support contacts for wellbeing and campus life.",
        contactEmail: "",
        contactPhone: "",
        location: "",
        url: "",
        audience: ["students"],
        order: 2,
        status: "published",
        createdAt: timestamp(),
        updatedAt: timestamp(),
      },
    },
    {
      id: "ict-helpdesk",
      data: {
        title: "ICT Helpdesk",
        category: "technology",
        description:
          "Technical support for app access, student systems, and online services.",
        contactEmail: "",
        contactPhone: "",
        location: "",
        url: "",
        audience: ["students", "staff"],
        order: 3,
        status: "published",
        createdAt: timestamp(),
        updatedAt: timestamp(),
      },
    },
  ]);
}

async function seedQuickLinksCollection(db) {
  if (!shouldSeedQuickLinks) {
    log("Skipping quick_links seeding.");
    return;
  }

  log("Seeding quick_links overrides...");
  await seedSimpleCollection(db, "quick_links", [
    {
      id: "sims_student_portal",
      data: {
        title: "SIMS STUDENT PORTAL",
        subtitle: "Registration, records and academic services",
        url: "https://student-portal.must.ac.ug/",
        order: 1,
        enabled: true,
      },
    },
    {
      id: "must_intelligent_student_advisor",
      data: {
        title: "MUST Intelligent Student Advisor",
        subtitle: "Student support and guidance",
        url: "https://misa.must.ac.ug/",
        order: 2,
        enabled: true,
      },
    },
    {
      id: "must_e_learning_platform",
      data: {
        title: "MUST E-LEARNING PLATFORM",
        subtitle: "Virtual learning environment",
        url: "https://vle.must.ac.ug/",
        order: 3,
        enabled: true,
      },
    },
    {
      id: "must_timetable",
      data: {
        title: "MUST TIMETABLE",
        subtitle: "Teaching and class schedules",
        url: "https://timetable.must.ac.ug/",
        order: 4,
        enabled: true,
      },
    },
  ]);
}

async function main() {
  log("");
  log("FAST restructured Firestore seeder (Node)");
  log(`Project: ${PROJECT_ID}`);
  log(`Dry run: ${dryRun}`);
  log(`Seed examples when empty: ${seedExamples}`);
  log(`Seed quick links: ${shouldSeedQuickLinks}`);
  log("");

  const db = await initializeFirestore();
  await seedOrMigrateDepartments(db);
  await seedOrMigrateStaff(db);
  await seedOrMigrateAnnouncements(db);
  await seedFacultyInfo(db);
  await seedFeaturedStories(db);
  await seedOrientationContent(db);
  await seedSupportResources(db);
  await seedQuickLinksCollection(db);

  log("");
  log("Seeder finished successfully.");
}

main().catch((error) => {
  console.error("Seeder failed:", error);
  process.exitCode = 1;
});
