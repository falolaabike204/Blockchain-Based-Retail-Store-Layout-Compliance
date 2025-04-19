;; Store Verification Contract
;; Validates legitimate retail locations

(define-data-var admin principal tx-sender)

;; Store data structure
(define-map stores
  { store-id: uint }
  {
    owner: principal,
    name: (string-utf8 100),
    location: (string-utf8 100),
    verified: bool,
    registration-date: uint
  }
)

;; Store ID counter
(define-data-var next-store-id uint u1)

;; Error codes
(define-constant ERR-NOT-AUTHORIZED u100)
(define-constant ERR-STORE-EXISTS u101)
(define-constant ERR-STORE-NOT-FOUND u102)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get admin))
)

;; Register a new store
(define-public (register-store (name (string-utf8 100)) (location (string-utf8 100)))
  (let
    (
      (store-id (var-get next-store-id))
    )
    (asserts! (is-none (map-get? stores { store-id: store-id })) (err ERR-STORE-EXISTS))

    (map-set stores
      { store-id: store-id }
      {
        owner: tx-sender,
        name: name,
        location: location,
        verified: false,
        registration-date: block-height
      }
    )

    (var-set next-store-id (+ store-id u1))
    (ok store-id)
  )
)

;; Verify a store (admin only)
(define-public (verify-store (store-id uint))
  (let
    (
      (store (unwrap! (map-get? stores { store-id: store-id }) (err ERR-STORE-NOT-FOUND)))
    )
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))

    (map-set stores
      { store-id: store-id }
      (merge store { verified: true })
    )

    (ok true)
  )
)

;; Get store details
(define-read-only (get-store (store-id uint))
  (map-get? stores { store-id: store-id })
)

;; Check if store is verified
(define-read-only (is-store-verified (store-id uint))
  (default-to false (get verified (map-get? stores { store-id: store-id })))
)

;; Transfer admin rights
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-admin) (err ERR-NOT-AUTHORIZED))
    (var-set admin new-admin)
    (ok true)
  )
)
