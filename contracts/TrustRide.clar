;; TrustRide - Cross-Platform Reputation System for Ride-Hailing
;; Immutable driver and rider ratings that follow users across platforms

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-OWNER-ONLY (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-ALREADY-EXISTS (err u102))
(define-constant ERR-INVALID-RATING (err u103))
(define-constant ERR-SELF-RATING (err u104))
(define-constant ERR-ALREADY-RATED (err u105))
(define-constant ERR-INVALID-USER-TYPE (err u106))
(define-constant ERR-TRIP-NOT-FOUND (err u107))
(define-constant ERR-UNAUTHORIZED (err u108))
(define-constant ERR-INVALID-INPUT (err u109))

;; Data Variables
(define-data-var next-trip-id uint u1)
(define-data-var platform-fee uint u100) ;; Fee in micro-STX for rating submission

;; Data Maps
(define-map user-profiles
  { user: principal }
  {
    user-type: (string-ascii 10), ;; "driver" or "rider" or "both"
    total-ratings: uint,
    rating-sum: uint,
    reputation-score: uint, ;; Calculated score out of 10000 (for precision)
    joined-at: uint,
    active: bool
  }
)

(define-map trip-records
  { trip-id: uint }
  {
    driver: principal,
    rider: principal,
    platform: (string-ascii 50),
    completed-at: uint,
    driver-rated: bool,
    rider-rated: bool,
    verified: bool
  }
)

(define-map ratings
  { trip-id: uint, rater: principal, ratee: principal }
  {
    rating: uint, ;; 1-5 stars
    comment: (string-ascii 200),
    timestamp: uint,
    verified: bool
  }
)

(define-map user-rating-history
  { user: principal, counter: uint }
  {
    trip-id: uint,
    rating: uint,
    timestamp: uint
  }
)

(define-map platform-integrations
  { platform: (string-ascii 50) }
  {
    active: bool,
    total-trips: uint,
    integration-date: uint
  }
)

;; Read-only functions
(define-read-only (get-user-profile (user principal))
  (map-get? user-profiles { user: user })
)

(define-read-only (get-user-reputation (user principal))
  (match (map-get? user-profiles { user: user })
    profile (get reputation-score profile)
    u0
  )
)

(define-read-only (get-trip-record (trip-id uint))
  (map-get? trip-records { trip-id: trip-id })
)

(define-read-only (get-rating (trip-id uint) (rater principal) (ratee principal))
  (map-get? ratings { trip-id: trip-id, rater: rater, ratee: ratee })
)

(define-read-only (get-platform-integration (platform (string-ascii 50)))
  (map-get? platform-integrations { platform: platform })
)

(define-read-only (calculate-reputation-score (total-ratings uint) (rating-sum uint))
  (if (> total-ratings u0)
    (/ (* rating-sum u2000) total-ratings) ;; Scale to 10000 max (5 stars * 2000)
    u0
  )
)

(define-read-only (get-user-average-rating (user principal))
  (match (map-get? user-profiles { user: user })
    profile 
      (if (> (get total-ratings profile) u0)
        (/ (get rating-sum profile) (get total-ratings profile))
        u0
      )
    u0
  )
)

;; Public functions
(define-public (register-user (user-type (string-ascii 10)))
  (let (
    (caller tx-sender)
    (validated-type (if (or (is-eq user-type "driver") (is-eq user-type "rider") (is-eq user-type "both")) user-type "rider"))
  )
    (asserts! (is-none (map-get? user-profiles { user: caller })) ERR-ALREADY-EXISTS)
    (asserts! (> (len user-type) u0) ERR-INVALID-INPUT)

    (map-set user-profiles
      { user: caller }
      {
        user-type: validated-type,
        total-ratings: u0,
        rating-sum: u0,
        reputation-score: u0,
        joined-at: block-height,
        active: true
      }
    )
    (ok true)
  )
)

(define-public (register-platform (platform (string-ascii 50)))
  (let (
    (caller tx-sender)
    (validated-platform (if (> (len platform) u0) platform "unknown"))
  )
    (asserts! (is-eq caller CONTRACT-OWNER) ERR-OWNER-ONLY)
    (asserts! (> (len platform) u0) ERR-INVALID-INPUT)
    (asserts! (is-none (map-get? platform-integrations { platform: platform })) ERR-ALREADY-EXISTS)

    (map-set platform-integrations
      { platform: validated-platform }
      {
        active: true,
        total-trips: u0,
        integration-date: block-height
      }
    )
    (ok true)
  )
)

(define-public (record-trip (driver principal) (rider principal) (platform (string-ascii 50)))
  (let (
    (trip-id (var-get next-trip-id))
    (caller tx-sender)
    (validated-platform (if (> (len platform) u0) platform "unknown"))
    (platform-data (map-get? platform-integrations { platform: platform }))
  )
    (asserts! (not (is-eq driver rider)) ERR-SELF-RATING)
    (asserts! (is-some (map-get? user-profiles { user: driver })) ERR-NOT-FOUND)
    (asserts! (is-some (map-get? user-profiles { user: rider })) ERR-NOT-FOUND)
    (asserts! (> (len platform) u0) ERR-INVALID-INPUT)

    (map-set trip-records
      { trip-id: trip-id }
      {
        driver: driver,
        rider: rider,
        platform: validated-platform,
        completed-at: block-height,
        driver-rated: false,
        rider-rated: false,
        verified: false
      }
    )

    ;; Update platform trip count if platform exists
    (match platform-data
      data (map-set platform-integrations
        { platform: validated-platform }
        (merge data { total-trips: (+ (get total-trips data) u1) })
      )
      true ;; Platform doesn't exist, continue anyway
    )

    (var-set next-trip-id (+ trip-id u1))
    (ok trip-id)
  )
)

(define-public (submit-rating (trip-id uint) (ratee principal) (rating uint) (comment (string-ascii 200)))
  (let (
    (caller tx-sender)
    (trip-data (unwrap! (get-trip-record trip-id) ERR-TRIP-NOT-FOUND))
    (ratee-profile (unwrap! (get-user-profile ratee) ERR-NOT-FOUND))
    (validated-rating (if (and (>= rating u1) (<= rating u5)) rating u3))
    (validated-comment (if (> (len comment) u0) comment "No comment"))
    (is-driver-rating (and (is-eq caller (get rider trip-data)) (is-eq ratee (get driver trip-data))))
    (is-rider-rating (and (is-eq caller (get driver trip-data)) (is-eq ratee (get rider trip-data))))
  )
    (asserts! (>= rating u1) ERR-INVALID-RATING)
    (asserts! (<= rating u5) ERR-INVALID-RATING)
    (asserts! (not (is-eq caller ratee)) ERR-SELF-RATING)
    (asserts! (or is-driver-rating is-rider-rating) ERR-UNAUTHORIZED)
    (asserts! (is-none (map-get? ratings { trip-id: trip-id, rater: caller, ratee: ratee })) ERR-ALREADY-RATED)

    ;; Record the rating
    (map-set ratings
      { trip-id: trip-id, rater: caller, ratee: ratee }
      {
        rating: validated-rating,
        comment: validated-comment,
        timestamp: block-height,
        verified: true
      }
    )

    ;; Update ratee's profile
    (let (
      (new-total-ratings (+ (get total-ratings ratee-profile) u1))
      (new-rating-sum (+ (get rating-sum ratee-profile) validated-rating))
      (new-reputation-score (calculate-reputation-score new-total-ratings new-rating-sum))
    )
      (map-set user-profiles
        { user: ratee }
        {
          user-type: (get user-type ratee-profile),
          total-ratings: new-total-ratings,
          rating-sum: new-rating-sum,
          reputation-score: new-reputation-score,
          joined-at: (get joined-at ratee-profile),
          active: (get active ratee-profile)
        }
      )
    )

    ;; Update trip record to mark rating as completed
    (if is-driver-rating
      (map-set trip-records
        { trip-id: trip-id }
        (merge trip-data { driver-rated: true })
      )
      (map-set trip-records
        { trip-id: trip-id }
        (merge trip-data { rider-rated: true })
      )
    )

    (ok true)
  )
)

(define-public (verify-trip (trip-id uint))
  (let (
    (caller tx-sender)
    (trip-data (unwrap! (get-trip-record trip-id) ERR-TRIP-NOT-FOUND))
    (validated-trip-id (if (> trip-id u0) trip-id u0))
  )
    (asserts! (is-eq caller CONTRACT-OWNER) ERR-OWNER-ONLY)
    (asserts! (> trip-id u0) ERR-INVALID-INPUT)

    (map-set trip-records
      { trip-id: validated-trip-id }
      {
        driver: (get driver trip-data),
        rider: (get rider trip-data),
        platform: (get platform trip-data),
        completed-at: (get completed-at trip-data),
        driver-rated: (get driver-rated trip-data),
        rider-rated: (get rider-rated trip-data),
        verified: true
      }
    )
    (ok true)
  )
)

(define-public (deactivate-user (user principal))
  (let (
    (caller tx-sender)
    (user-data (unwrap! (get-user-profile user) ERR-NOT-FOUND))
    (validated-user-type (get user-type user-data))
    (validated-total-ratings (get total-ratings user-data))
    (validated-rating-sum (get rating-sum user-data))
    (validated-reputation-score (get reputation-score user-data))
    (validated-joined-at (get joined-at user-data))
  )
    (asserts! (is-eq caller CONTRACT-OWNER) ERR-OWNER-ONLY)

    (map-set user-profiles
      { user: user }
      {
        user-type: validated-user-type,
        total-ratings: validated-total-ratings,
        rating-sum: validated-rating-sum,
        reputation-score: validated-reputation-score,
        joined-at: validated-joined-at,
        active: false
      }
    )
    (ok true)
  )
)

(define-public (update-platform-fee (new-fee uint))
  (let (
    (caller tx-sender)
    (validated-fee (if (<= new-fee u10000) new-fee u100)) ;; Cap at 10000 micro-STX
  )
    (asserts! (is-eq caller CONTRACT-OWNER) ERR-OWNER-ONLY)
    (asserts! (<= new-fee u10000) ERR-INVALID-INPUT) ;; Reasonable fee limit

    (var-set platform-fee validated-fee)
    (ok true)
  )
)
