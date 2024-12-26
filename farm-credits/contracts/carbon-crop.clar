;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_INVALID_AMOUNT (err u101))
(define-constant ERR_INSUFFICIENT_BALANCE (err u102))
(define-constant ERR_NOT_FOUND (err u103))
(define-constant ERR_ALREADY_LISTED (err u104))
(define-constant MIN_VERIFICATION_PERIOD u2592000) ;; 30 days in seconds
(define-constant TOKEN_PRECISION u6) ;; 6 decimal places for token amounts

;; Data Variables and Maps
(define-data-var total-supply uint u0)
(define-data-var inspector-registry (list 50 principal) (list))

;; Farm data storage
(define-map farm-data
  { farm-id: uint, owner: principal }
  { carbon-score: uint,
    water-score: uint,
    chemical-reduction: uint,
    last-verified: uint,
    total-rewards: uint })

;; Token balances
(define-map token-balances 
  principal 
  uint)

;; Marketplace listings
(define-map market-listings
  uint  ;; listing-id
  { seller: principal,
    amount: uint,
    price-per-token: uint,
    active: bool })

;; Reputation scores
(define-map reputation-scores
  principal
  { successful-trades: uint,
    verification-count: uint })

;; Administrative Functions
(define-public (register-inspector (inspector-principal principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_NOT_AUTHORIZED)
    (asserts! (not (is-eq inspector-principal CONTRACT_OWNER)) ERR_NOT_AUTHORIZED)  ;; Prevent owner from being inspector
    (let ((new-registry (unwrap! (as-max-len? (append (var-get inspector-registry) inspector-principal) u50) ERR_NOT_AUTHORIZED)))
      (ok (var-set inspector-registry new-registry)))))
   
;; Farm Verification Functions
(define-public (submit-verification
    (farm-id uint)
    (farm-owner principal)
    (carbon-score uint)
    (water-score uint)
    (chemical-reduction uint))
  (begin
    ;; Add input validation
    (asserts! (> farm-id u0) ERR_INVALID_AMOUNT)  ;; Ensure valid farm ID
    (asserts! (not (is-eq farm-owner CONTRACT_OWNER)) ERR_NOT_AUTHORIZED)  ;; Prevent owner manipulation
    (asserts! (<= carbon-score u10000) ERR_INVALID_AMOUNT)  ;; Set reasonable limits
    (asserts! (<= water-score u10000) ERR_INVALID_AMOUNT)
    (asserts! (<= chemical-reduction u10000) ERR_INVALID_AMOUNT)

    (let 
      ((previous-data (default-to 
          { carbon-score: u0, water-score: u0, chemical-reduction: u0, last-verified: u0, total-rewards: u0 }
          (map-get? farm-data {farm-id: farm-id, owner: farm-owner}))))
      (asserts! (is-some (index-of (var-get inspector-registry) tx-sender)) ERR_NOT_AUTHORIZED)
      (asserts! (> block-height (+ (get last-verified previous-data) MIN_VERIFICATION_PERIOD)) ERR_NOT_AUTHORIZED)
      
      (let 
        ((carbon-improvement (- carbon-score (get carbon-score previous-data)))
         (water-improvement (- water-score (get water-score previous-data)))
         (chemical-improvement (- chemical-reduction (get chemical-reduction previous-data)))
         (total-improvement (+ carbon-improvement water-improvement chemical-improvement))
         (reward-amount (* total-improvement u1000000)))

        ;; Validate improvements and reward
        (asserts! (>= carbon-improvement u0) ERR_INVALID_AMOUNT)
        (asserts! (>= water-improvement u0) ERR_INVALID_AMOUNT)
        (asserts! (>= chemical-improvement u0) ERR_INVALID_AMOUNT)
        (asserts! (> reward-amount u0) ERR_INVALID_AMOUNT)
        
        (unwrap-panic (mint-tokens farm-owner reward-amount))
        
        (ok (map-set farm-data
          {farm-id: farm-id, owner: farm-owner}
          { carbon-score: carbon-score,
            water-score: water-score,
            chemical-reduction: chemical-reduction,
            last-verified: block-height,
            total-rewards: (+ (get total-rewards previous-data) reward-amount) }))))))

;; Token Functions
(define-private (mint-tokens (recipient principal) (amount uint))
  (begin
    (var-set total-supply (+ (var-get total-supply) amount))
    (map-set token-balances 
        recipient
        (+ (default-to u0 (map-get? token-balances recipient)) amount))
    (ok amount)))  ;; Return the minted amount for better error tracking

(define-public (transfer (recipient principal) (amount uint))
  (begin
    (asserts! (not (is-eq recipient tx-sender)) ERR_NOT_AUTHORIZED)  ;; Prevent self-transfer
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)  ;; Ensure positive amount
    (let ((sender-balance (default-to u0 (map-get? token-balances tx-sender))))
      (asserts! (>= sender-balance amount) ERR_INSUFFICIENT_BALANCE)
      (map-set token-balances
        tx-sender
        (- sender-balance amount))
      (map-set token-balances
        recipient
        (+ (default-to u0 (map-get? token-balances recipient)) amount))
      (ok true))))

;; Marketplace Functions
(define-public (create-listing (listing-id uint) (amount uint) (price-per-token uint))
  (begin
    (asserts! (> listing-id u0) ERR_INVALID_AMOUNT)  ;; Ensure valid listing ID
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)  ;; Ensure positive amount
    (asserts! (> price-per-token u0) ERR_INVALID_AMOUNT)  ;; Ensure positive price
    (let ((seller-balance (default-to u0 (map-get? token-balances tx-sender))))
      (asserts! (>= seller-balance amount) ERR_INSUFFICIENT_BALANCE)
      (asserts! (is-none (map-get? market-listings listing-id)) ERR_ALREADY_LISTED)
      
      (try! (transfer CONTRACT_OWNER amount))
      
      (ok (map-set market-listings
        listing-id
        { seller: tx-sender,
          amount: amount,
          price-per-token: price-per-token,
          active: true })))))

;; Reputation Functions

(define-private (update-reputation (user principal))
  (let ((current-score (default-to 
        { successful-trades: u0, verification-count: u0 }
        (map-get? reputation-scores user))))
    (map-set reputation-scores
      user
      (merge current-score 
        { successful-trades: (+ (get successful-trades current-score) u1) }))))

;; Read-only Functions

(define-read-only (get-balance (user principal))
  (ok (default-to u0 (map-get? token-balances user))))

(define-read-only (get-farm-data (farm-id uint) (owner principal))
  (map-get? farm-data {farm-id: farm-id, owner: owner}))

(define-read-only (get-listing (listing-id uint))
  (map-get? market-listings listing-id))

(define-read-only (get-reputation (user principal))
  (map-get? reputation-scores user))