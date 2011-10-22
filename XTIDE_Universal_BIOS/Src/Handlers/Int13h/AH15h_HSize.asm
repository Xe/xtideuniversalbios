; Project name	:	XTIDE Universal BIOS
; Description	:	Int 13h function AH=15h, Read Disk Drive Size.

; Section containing code
SECTION .text

;--------------------------------------------------------------------
; Int 13h function AH=15h, Read Disk Drive Size.
;
; AH15h_HandlerForReadDiskDriveSize
;	Parameters:
;		DL:		Translated Drive number
;		DS:DI:	Ptr to DPT (in RAMVARS segment)
;		SS:BP:	Ptr to IDEPACK
;	Returns with INTPACK:
;		If succesfull:
;			AH:		3 (Hard disk accessible)
;			CX:DX:	Total number of sectors
;			CF:		0
;		If failed:
;			AH:		0 (Drive not present)
;			CX:DX:	0
;			CF:		1
;--------------------------------------------------------------------
ALIGN JUMP_ALIGN
AH15h_HandlerForReadDiskDriveSize:
	call	AH15h_GetSectorCountToDXAX
	mov		[bp+IDEPACK.intpack+INTPACK.cx], dx			; HIWORD to CX
	mov		[bp+IDEPACK.intpack+INTPACK.dx], ax			; LOWORD to DX

	xor		ah, ah
	call	Int13h_SetErrorCodeToIntpackInSSBPfromAH	; Store success to BDA and CF
	mov		BYTE [bp+IDEPACK.intpack+INTPACK.ah], 3		; Type code = Hard disk
	jmp		Int13h_ReturnFromHandlerWithoutStoringErrorCode


;--------------------------------------------------------------------
; AH15h_GetSectorCountFromForeignDriveToDXAX:
; AH15h_GetSectorCountToDXAX:
;	Parameters:
;		DL:		Drive number
;		DS:		RAMVARS segment
;		DS:DI:	Ptr to DPT (AH15h_GetSectorCount only)
;	Returns:
;		DX:AX:	Total sector count
;		BX:		Zero
;	Corrupts registers:
;		CX
;--------------------------------------------------------------------
AH15h_GetSectorCountFromForeignDriveToDXAX:
	mov		ah, GET_DRIVE_PARAMETERS
	call	Int13h_CallPreviousInt13hHandler
	jmp		SHORT ConvertAH08hReturnValuesToSectorCount

ALIGN JUMP_ALIGN
AH15h_GetSectorCountToDXAX:
	call	AH8h_GetDriveParameters
	; Fall to ConvertAH08hReturnValuesToSectorCount

ConvertAH08hReturnValuesToSectorCount:
	call	Address_ExtractLCHSparametersFromOldInt13hAddress
	xor		ax, ax			; Zero AX
	inc		cx				; Max cylinder number to cylinder count
	xchg	al, bh			; AX=Max head number, BX=Sectors per track
	inc		ax				; AX=Head count
	mul		bx				; AX=Head count * Sectors per track
	mul		cx				; DX:AX = Total sector count
	xor		bx, bx			; Zero BX for 48-bit sector count (and clear CF)
	ret