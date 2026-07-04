import "@typespec/http";

using Http;

/**
 * School Portal HTTP/JSON API.
 *
 * School Portal (`schoolus`) is a prototype Sneat extension: a school
 * administrator opens a school within their business space, defines academic
 * terms and classes, enrols students against a class, publishes a class
 * timetable, and teachers mark daily attendance. A public read exposes a
 * lightweight projection of the school.
 *
 * This is the **frozen wire contract** between the Go backend
 * (`schoolus/backend`) and the frontend — no emitters are configured, the
 * `.tsp` is the source of truth for the wire shape only; both sides
 * hand-implement matching types (same convention as `eventius/typespec` and
 * the `sneat-go/typespec` directory). The matching Go DTOs live in
 * `../backend/dto4schoolus/dto.go`.
 *
 * Source: backstage `docs/superpowers/specs/2026-07-04-schoolus-prototype-design.md`.
 *
 * Auth: school creation, class creation, enrolment and attendance marking all
 * require `Authorization: Bearer <token>` and caller membership of
 * `{spaceID}` (the school's business space). The public school page needs NO
 * auth. The class timetable read requires membership of `{spaceID}`.
 */
@service(#{ title: "School Portal API" })
@route("/v0/api4schoolus")
namespace Api4Schoolus;

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

/** Kind of school. */
enum SchoolType {
  language,
  music,
  tutoring,
  primary,
  secondary,
  international,
  dance,
  driving,
  sports,
  training,
}

/** Attendance mark for a student on a given date. */
enum AttendanceStatus {
  present,
  absent,
  late,
  excused,
}

/** Lifecycle of a student's enrolment in a class. */
enum EnrolmentStatus {
  active,
  withdrawn,
  graduated,
}

/** A person's role within a school space. */
enum SchoolRole {
  owner,
  principal,
  vice_principal,
  administrator,
  office_staff,
  teacher,
  assistant_teacher,
  coach,
  student,
  parent,
  guardian,
  accountant,
  nurse,
  librarian,
  transport_coordinator,
  external_tutor,
  guest,
}

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

/** POST body to create a school within the administrator's space. */
model CreateSchoolRequest {
  title: string;

  type: SchoolType;

  /** Free-text location, e.g. "Dublin, IE". */
  location?: string;

  /** Public description shown on the school page. */
  description?: string;
}

/** Identifies the new school so the UI can navigate to it. */
model CreateSchoolResponse {
  id: string;

  /** Site-relative public school page path, e.g. "/school/abc". */
  publicPath: string;
}

/** The unauthenticated public projection of a school. */
model SchoolPublic {
  id: string;
  title: string;
  type: SchoolType;
  location?: string;
  description?: string;
}

/** An academic term (period the school operates classes over). */
model Term {
  id: string;
  title: string;
  startDate: plainDate;
  endDate: plainDate;
}

/** A class (group of enrolled students) within a school. */
model SchoolClass {
  id: string;
  title: string;

  /** The term this class runs in. */
  termID: string;

  /** UID of the teacher who owns the class. */
  teacherUID?: string;

  /** Room or venue label, e.g. "Room 2B". */
  room?: string;
}

/** POST body to create a class within a school. */
model CreateClassRequest {
  title: string;
  termID: string;
  teacherUID?: string;
  room?: string;
}

/** Identifies the new class. */
model CreateClassResponse {
  id: string;
}

/**
 * Body to enrol a student into a class. The server stamps `enrolledAt` and
 * defaults `status` to `active` on the resulting `Enrolment`.
 */
model EnrolStudentRequest {
  /** UID of the student being enrolled. */
  studentUID: string;

  /** Display name captured at enrolment time. */
  studentName: string;

  /** UID of the enrolling guardian, if the student is a minor. */
  guardianUID?: string;
}

/** A student's enrolment record in a class. */
model Enrolment {
  id: string;
  classID: string;
  studentUID: string;
  studentName: string;
  guardianUID?: string;
  status: EnrolmentStatus;
  enrolledAt: utcDateTime;
}

/** Identifies the new enrolment. */
model EnrolStudentResponse {
  id: string;
  status: EnrolmentStatus;
}

/** One scheduled slot in a class timetable. */
model TimetableEntry {
  id: string;
  classID: string;

  /** Subject or lesson label, e.g. "Algebra". */
  subject: string;

  /** Day of week, 0=Sunday .. 6=Saturday. */
  weekday: int32;

  /** Local start time "HH:MM". */
  startTime: string;

  /** Local end time "HH:MM". */
  endTime: string;

  room?: string;
}

/** POST body to mark attendance for one student on a date. */
model MarkAttendanceRequest {
  studentUID: string;

  /** The date the mark applies to. */
  date: plainDate;

  status: AttendanceStatus;

  /** Optional free-text note, e.g. reason for an excused absence. */
  note?: string;
}

/** A recorded attendance mark. */
model AttendanceRecord {
  id: string;
  classID: string;
  studentUID: string;
  date: plainDate;
  status: AttendanceStatus;
  note?: string;

  /** UID of the person (teacher) who recorded the mark. */
  markedByUID: string;
  markedAt: utcDateTime;
}

// ---------------------------------------------------------------------------
// Operations
// ---------------------------------------------------------------------------

@tag("schools")
interface Schools {
  /**
   * Create a school within `{spaceID}`. Caller MUST be a member of the space
   * (the administrator). Returns the new school's id and public path.
   */
  @post
  @route("/spaces/{spaceID}/schools")
  @useAuth(BearerAuth)
  createSchool(@path spaceID: string, @body body: CreateSchoolRequest): {
    @statusCode statusCode: 201;
    @body school: CreateSchoolResponse;
  };

  /** Fetch the public projection of a school. No auth required. */
  @get
  @route("/schools/{schoolID}")
  getSchoolPublic(@path schoolID: string): SchoolPublic;
}

@tag("classes")
interface Classes {
  /**
   * Create a class within a school. Caller MUST be a member of `{spaceID}`.
   */
  @post
  @route("/spaces/{spaceID}/schools/{schoolID}/classes")
  @useAuth(BearerAuth)
  createClass(
    @path spaceID: string,
    @path schoolID: string,
    @body body: CreateClassRequest,
  ): {
    @statusCode statusCode: 201;
    @body class: CreateClassResponse;
  };

  /**
   * List the timetable for a class. Caller MUST be a member of `{spaceID}`.
   */
  @get
  @route("/spaces/{spaceID}/classes/{classID}/timetable")
  @useAuth(BearerAuth)
  getClassTimetable(
    @path spaceID: string,
    @path classID: string,
  ): TimetableEntry[];
}

@tag("enrolments")
interface Enrolments {
  /**
   * Enrol a student into a class. Caller MUST be a member of `{spaceID}`. The
   * server stamps `enrolledAt` and defaults `status` to `active`.
   */
  @post
  @route("/spaces/{spaceID}/classes/{classID}/enrolments")
  @useAuth(BearerAuth)
  enrolStudent(
    @path spaceID: string,
    @path classID: string,
    @body body: EnrolStudentRequest,
  ): {
    @statusCode statusCode: 201;
    @body enrolment: EnrolStudentResponse;
  };
}

@tag("attendance")
interface Attendance {
  /**
   * Mark attendance for a student in a class. Caller MUST be a member of
   * `{spaceID}` (typically the class teacher); the server stamps the caller's
   * uid as `markedByUID` and sets `markedAt`.
   */
  @post
  @route("/spaces/{spaceID}/classes/{classID}/attendance")
  @useAuth(BearerAuth)
  markAttendance(
    @path spaceID: string,
    @path classID: string,
    @body body: MarkAttendanceRequest,
  ): {
    @statusCode statusCode: 201;
    @body record: AttendanceRecord;
  };
}
