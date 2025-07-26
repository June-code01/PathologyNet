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

(define-public (register-pathologist
  (pathologist-id principal)
  (full-name (string-ascii 100))
  (medical-license (string-ascii 50))
  (subspecialty (string-ascii 100))
  (board-certification (string-ascii 50))
  (years-experience uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) ERR_NOT_AUTHORIZED)
    (map-set pathologist-profiles
      { pathologist-id: pathologist-id }
      {
        full-name: full-name,
        medical-license: medical-license,
        subspecialty: subspecialty,
        board-certification: board-certification,
        years-experience: years-experience,
        case-load: u0,
        accuracy-rating: u95,
        is-active: true
      }
    )
    (ok true)
  )
)

(define-public (submit-pathology-sample
  (patient-id principal)
  (sample-type (string-ascii 50))
  (anatomical-site (string-ascii 100))
  (preservation-method (string-ascii 50))
  (assigned-pathologist principal)
  (processing-priority (string-ascii 20))
  (chain-of-custody (string-ascii 200)))
  (let ((sample-id (var-get next-sample-id))
        (pathologist-data (unwrap! (map-get? pathologist-profiles { pathologist-id: assigned-pathologist }) ERR_INVALID_PATHOLOGIST)))
    (asserts! (get is-active pathologist-data) ERR_INVALID_PATHOLOGIST)
    (map-set pathology-samples
      { sample-id: sample-id }
      {
        patient-id: patient-id,
        collecting-physician: tx-sender,
        sample-type: sample-type,
        anatomical-site: anatomical-site,
        collection-date: block-height,
        preservation-method: preservation-method,
        assigned-pathologist: assigned-pathologist,
        processing-priority: processing-priority,
        sample-quality: "acceptable",
        chain-of-custody: chain-of-custody
      }
    )
    (map-set pathologist-profiles
      { pathologist-id: assigned-pathologist }
      (merge pathologist-data { case-load: (+ (get case-load pathologist-data) u1) })
    )
    (var-set next-sample-id (+ sample-id u1))
    (ok sample-id)
  )
)

(define-public (update-sample-quality
  (sample-id uint)
  (sample-quality (string-ascii 30)))
  (let ((sample-data (unwrap! (map-get? pathology-samples { sample-id: sample-id }) ERR_SAMPLE_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get assigned-pathologist sample-data)) ERR_NOT_AUTHORIZED)
    (map-set pathology-samples
      { sample-id: sample-id }
      (merge sample-data { sample-quality: sample-quality })
    )
    (ok true)
  )
)

(define-public (submit-diagnosis
  (sample-id uint)
  (primary-diagnosis (string-ascii 200))
  (secondary-diagnoses (string-ascii 300))
  (microscopic-findings (string-ascii 500))
  (immunohistochemistry (string-ascii 300))
  (molecular-markers (string-ascii 200))
  (grade-stage (string-ascii 100))
  (margins-status (string-ascii 100))
  (diagnosis-confidence uint))
  (let ((sample-data (unwrap! (map-get? pathology-samples { sample-id: sample-id }) ERR_SAMPLE_NOT_FOUND))
        (existing-diagnosis (map-get? pathology-diagnoses { sample-id: sample-id })))
    (asserts! (is-eq tx-sender (get assigned-pathologist sample-data)) ERR_NOT_AUTHORIZED)
    (asserts! (is-none existing-diagnosis) ERR_DIAGNOSIS_EXISTS)
    (asserts! (not (is-eq (get sample-quality sample-data) "contaminated")) ERR_SAMPLE_CONTAMINATED)
    (map-set pathology-diagnoses
      { sample-id: sample-id }
      {
        primary-diagnosis: primary-diagnosis,
        secondary-diagnoses: secondary-diagnoses,
        microscopic-findings: microscopic-findings,
        immunohistochemistry: immunohistochemistry,
        molecular-markers: molecular-markers,
        grade-stage: grade-stage,
        margins-status: margins-status,
        diagnosis-confidence: diagnosis-confidence,
        pathologist-id: tx-sender,
        diagnosis-date: block-height
      }
    )
    (ok true)
  )
)

(define-public (request-second-opinion
  (sample-id uint)
  (consulting-pathologist principal)
  (consultation-reason (string-ascii 200)))
  (let ((sample-data (unwrap! (map-get? pathology-samples { sample-id: sample-id }) ERR_SAMPLE_NOT_FOUND))
        (consultant-data (unwrap! (map-get? pathologist-profiles { pathologist-id: consulting-pathologist }) ERR_INVALID_PATHOLOGIST))
        (opinion-id (var-get next-opinion-id)))
    (asserts! (is-eq tx-sender (get assigned-pathologist sample-data)) ERR_NOT_AUTHORIZED)
    (asserts! (get is-active consultant-data) ERR_INVALID_PATHOLOGIST)
    (map-set second-opinions
      { sample-id: sample-id, opinion-id: opinion-id }
      {
        requesting-pathologist: tx-sender,
        consulting-pathologist: consulting-pathologist,
        consultation-reason: consultation-reason,
        consultant-findings: "",
        agreement-level: "pending",
        consultation-date: block-height,
        final-recommendation: ""
      }
    )
    (var-set next-opinion-id (+ opinion-id u1))
    (ok opinion-id)
  )
)

(define-public (provide-consultation
  (sample-id uint)
  (opinion-id uint)
  (consultant-findings (string-ascii 400))
  (agreement-level (string-ascii 30))
  (final-recommendation (string-ascii 300)))
  (let ((opinion-data (unwrap! (map-get? second-opinions { sample-id: sample-id, opinion-id: opinion-id }) ERR_SAMPLE_NOT_FOUND)))
    (asserts! (is-eq tx-sender (get consulting-pathologist opinion-data)) ERR_NOT_AUTHORIZED)
    (asserts! (is-eq (get agreement-level opinion-data) "pending") ERR_NOT_AUTHORIZED)
    (map-set second-opinions
      { sample-id: sample-id, opinion-id: opinion-id }
      (merge opinion-data {
        consultant-findings: consultant-findings,
        agreement-level: agreement-level,
        final-recommendation: final-recommendation
      })
    )
    (ok true)
  )
)

(define-public (conduct-quality-assurance
  (sample-id uint)
  (staining-quality (string-ascii 30))
  (sectioning-quality (string-ascii 30))
  (diagnostic-accuracy (string-ascii 30))
  (corrective-actions (string-ascii 200))
  (qa-passed bool))
  (let ((sample-data (unwrap! (map-get? pathology-samples { sample-id: sample-id }) ERR_SAMPLE_NOT_FOUND)))
    (asserts! (is-eq tx-sender contract-owner) ERR_NOT_AUTHORIZED)
    (map-set quality-assurance
      { sample-id: sample-id }
      {
        qa-reviewer: tx-sender,
        review-date: block-height,
        staining-quality: staining-quality,
        sectioning-quality: sectioning-quality,
        diagnostic-accuracy: diagnostic-accuracy,
        corrective-actions: corrective-actions,
        qa-passed: qa-passed
      }
    )
    (ok true)
  )
)

(define-public (add-molecular-test
  (sample-id uint)
  (test-type (string-ascii 100))
  (testing-lab principal)
  (test-method (string-ascii 50))
  (target-genes (string-ascii 200))
  (test-results (string-ascii 400))
  (clinical-significance (string-ascii 300)))
  (let ((sample-data (unwrap! (map-get? pathology-samples { sample-id: sample-id }) ERR_SAMPLE_NOT_FOUND))
        (test-id (var-get next-test-id)))
    (asserts! (is-eq tx-sender (get assigned-pathologist sample-data)) ERR_NOT_AUTHORIZED)
    (map-set molecular-testing
      { sample-id: sample-id, test-id: test-id }
      {
        test-type: test-type,
        testing-lab: testing-lab,
        test-method: test-method,
        target-genes: target-genes,
        test-results: test-results,
        clinical-significance: clinical-significance,
        test-date: block-height
      }
    )
    (var-set next-test-id (+ test-id u1))
    (ok test-id)
  )
)

(define-read-only (get-pathology-sample (sample-id uint))
  (map-get? pathology-samples { sample-id: sample-id })
)

(define-read-only (get-pathology-diagnosis (sample-id uint))
  (map-get? pathology-diagnoses { sample-id: sample-id })
)

(define-read-only (get-pathologist-profile (pathologist-id principal))
  (map-get? pathologist-profiles { pathologist-id: pathologist-id })
)

(define-read-only (get-second-opinion (sample-id uint) (opinion-id uint))
  (map-get? second-opinions { sample-id: sample-id, opinion-id: opinion-id })
)

(define-read-only (get-quality-assurance (sample-id uint))
  (map-get? quality-assurance { sample-id: sample-id })
)

(define-read-only (get-molecular-test (sample-id uint) (test-id uint))
  (map-get? molecular-testing { sample-id: sample-id, test-id: test-id })
)

(define-read-only (get-next-sample-id)
  (var-get next-sample-id)
)

(define-read-only (get-next-opinion-id)
  (var-get next-opinion-id)
)

(define-read-only (get-next-test-id)
  (var-get next-test-id)
)