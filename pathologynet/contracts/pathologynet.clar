;; PathologyNet - Pathology Sample and Diagnosis Management
;; Version: 1.0.0

(define-constant ERR_NOT_AUTHORIZED (err u300))
(define-constant ERR_SAMPLE_NOT_FOUND (err u301))
(define-constant ERR_INVALID_PATHOLOGIST (err u302))
(define-constant ERR_SAMPLE_CONTAMINATED (err u303))
(define-constant ERR_DIAGNOSIS_EXISTS (err u304))

(define-map pathology-samples
  { sample-id: uint }
  {
    patient-id: principal,
    collecting-physician: principal,
    sample-type: (string-ascii 50),
    anatomical-site: (string-ascii 100),
    collection-date: uint,
    preservation-method: (string-ascii 50),
    assigned-pathologist: principal,
    processing-priority: (string-ascii 20),
    sample-quality: (string-ascii 30),
    chain-of-custody: (string-ascii 200)
  }
)

(define-map pathology-diagnoses
  { sample-id: uint }
  {
    primary-diagnosis: (string-ascii 200),
    secondary-diagnoses: (string-ascii 300),
    microscopic-findings: (string-ascii 500),
    immunohistochemistry: (string-ascii 300),
    molecular-markers: (string-ascii 200),
    grade-stage: (string-ascii 100),
    margins-status: (string-ascii 100),
    diagnosis-confidence: uint,
    pathologist-id: principal,
    diagnosis-date: uint
  }
)

(define-map pathologist-profiles
  { pathologist-id: principal }
  {
    full-name: (string-ascii 100),
    medical-license: (string-ascii 50),
    subspecialty: (string-ascii 100),
    board-certification: (string-ascii 50),
    years-experience: uint,
    case-load: uint,
    accuracy-rating: uint,
    is-active: bool
  }
)

(define-map second-opinions
  { sample-id: uint, opinion-id: uint }
  {
    requesting-pathologist: principal,
    consulting-pathologist: principal,
    consultation-reason: (string-ascii 200),
    consultant-findings: (string-ascii 400),
    agreement-level: (string-ascii 30),
    consultation-date: uint,
    final-recommendation: (string-ascii 300)
  }
)

(define-map quality-assurance
  { sample-id: uint }
  {
    qa-reviewer: principal,
    review-date: uint,
    staining-quality: (string-ascii 30),
    sectioning-quality: (string-ascii 30),
    diagnostic-accuracy: (string-ascii 30),
    corrective-actions: (string-ascii 200),
    qa-passed: bool
  }
)

(define-map molecular-testing
  { sample-id: uint, test-id: uint }
  {
    test-type: (string-ascii 100),
    testing-lab: principal,
    test-method: (string-ascii 50),
    target-genes: (string-ascii 200),
    test-results: (string-ascii 400),
    clinical-significance: (string-ascii 300),
    test-date: uint
  }
)

(define-data-var next-sample-id uint u1)
(define-data-var next-opinion-id uint u1)
(define-data-var next-test-id uint u1)

(define-constant contract-owner tx-sender)