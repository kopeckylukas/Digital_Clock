;Program pro �ten� �asov�ho �daje z obvodu RTC 72421
;Aktu�ln� verze


ORG	0000H
	JMP START

ORG	0003H		;vektor p�eru�en� INT0
	JMP CTENI

;Registry pro nastaven� periody zobrazov�n� datumu a doby
;trv�n� zobrazen� datumu. Pou��v� je podprogram PREP.

DOBA_D	EQU	5BH	;registr pro �schovu hodnoty DOBA
PER_D	EQU	5AH	;registr pro �schovu hodnoty PER
DOBA	EQU	59H	;doba trv�n� zobrazen� datumu
PER	EQU	58H	;perioda zobrazov�n� datumu

;Registry pro do�asn� ulo�en� �daj� o datumu a �asu.
;Registry jsou pln�ny programem CTENI, co� je obslu�n�
;rutina extern�ho p�eru�en� INT0. Aktualizace dat je
;prov�d�na 1x za sekundu (INT generuje RTC)

H10	EQU	57H	;na�ten� des�tky hodin
H1	EQU	56H	;na�ten� jednotky hodin
MI10	EQU	55H	;na�ten� des�tky minut
MI1	EQU	54H	;na�ten� jednotky minut
S10	EQU	53H	;na�ten� des�tky sekund
S1	EQU	52H	;na�ten� jednotky sekund
DEN_W	EQU	51H	;na�ten� ��slo dne v t�dnu
ROK10	EQU	50H	;na�ten� des�tky rok�
ROK1	EQU	4FH	;na�ten� jednotky rok�
MES10	EQU	4EH	;na�ten� des�tky m�s�c�
MES1	EQU	4DH	;na�ten� jednotky m�s�c�
DEN10	EQU	4CH	;na�ten� des�tky dn�
DEN1	EQU	4BH	;na�ten� jednotky dn�

;Definice registr� pro ru�n� nastavov�n� aktu�ln�ho �asu
;Pou��vaj� se jako po�itadla, kter� jsou pot� p�evedena
;pomoc� podprogram� BCD_XXX do k�du BCD a ulo�ena do
;odpov�daj�c�ch registr�

DEN	EQU	4AH	;registr ��sla dne v t�dnu (0 = ned�le)
ROKY	EQU	49H	;registr rok�
MESICE	EQU	48H	;registr m�s�c�
DNY	EQU	47H	;registr dn�
HOD	EQU	46H	;registr hodin
MIN	EQU	45H	;regist minut
SEK	EQU	44H	;registr sekund

;Definice registr� pro nastaven� �asov�ch �daj� v RTC
;�daje v t�chto registrech jsou pova�ov�ny za platn� data
;a pomoc� podprogramu ZAPIS jsou zaps�na do registr� RTC,
;kter� je n�sledn� odblokov�n a �asom�ra se rozeb�hne.

W_NEW	EQU	43H	;nov� den v t�dnu (0 je ned�le)
Y10_NEW	EQU	42H	;nov� des�tky let (0 a� 9)
Y1_NEW	EQU	41H	;nov� jednotky let (0 a� 9)
M10_NEW	EQU	40H	;nov� des�tky m�s�c� (0 nebo 1)
M1_NEW	EQU	3FH	;nov� jednotky m�s�c� (0 a� 9)
D10_NEW	EQU	3EH	;nov� des�tky dn� (0 a� 3)
D1_NEW	EQU	3DH	;nov� jednotky dn� (0 a� 9)
H10_NEW	EQU	3CH	;nov� des�tky hodin (0 a� 2)
H1_NEW	EQU	3BH	;nov� jednotky hodin (0 a� 9)
MI10_NEW EQU	3AH	;nov� des�tky minut (0 a� 5)
MI1_NEW	EQU	39H	;nov� jednotky minut (0 a� 9)
S10_NEW	EQU	38H	;nov� des�tky sekund (0 a� 5)
S1_NEW	EQU	37H	;nov� jednotky sekund (0 a� 9)


;videoRAM

;Definice registr� aktu�ln�ch �asov�ch �daj�
;�as je zobrazov�n na 7mi m�stn�m displeji ve form�tu WHHMMSS
;Pracuje se s 24 hodinov�m cyklem

SEK_JED	EQU	36H	;jedn� se o adresy 7mi segmentovek
SEK_DES	EQU	35H
MIN_JED	EQU	34H
MIN_DES	EQU	33H
HOD_JED	EQU	32H
HOD_DES	EQU	31H
DEN_TYD	EQU	30H

;Definice portu a bit�

I_O	EQU	P2	;port ovl�daj�c� RTC
BUSY	BIT	P2.5	;na�ten� bit BUSY
RDG	BIT	P3.0	;�ten� RTC (aktivn� v L)
WRT	BIT	P3.1	;z�pis do RTC (aktivn� v L)
RESET	BIT	P0.0	;tla��tko RESET
NAS_HOD	BIT	P0.1	;tla��tko pro nastaven� hodin, resp. dn�
NAS_MIN	BIT	P0.2	;tla��tko pro nastaven� minut, resp. m�s�c�
NAS_SEK	BIT	P0.3	;tla��tko pro nastaven� sekund, resp. rok�
DAT_TIM	BIT	P0.5	;sp�na� pro funkci automatick�ho zobrazov�n� datumu
TIM_DAT	BIT	P0.6	;tla��tko pro p�ep�n�n� re�imu zobrazen� �as/datum
SETING	BIT	P0.4	;tla��tko SET pro aktualizaci �asov�ch �daj�
ADJUST	BIT	7EH	;pomocn� bit (vlajka) pro um�l� vyvol�n� RESET
DATUM	BIT	7DH	;pomocn� bit (vlajka) pro nastaven� aktu�ln�ho datumu a dne v t�dnu
TIME	BIT	7CH	;pomocn� bit ur�uj�c� (vlajka), zda se zobrazuje �as nebo datum
ERROR	BIT	7BH	;pomocn� bit (vlajka) indikuj�c� chybu p�i kontrole dat v registrech RTC
LE1	BIT	P1.5	;bity LE (Latch Enable) poskytuj� z�p�sov� pulzy pro
LE2	BIT	P1.6	;dekod�ry sedmisegmentovek (aktivn� je sestupn� hrana)
LE3	BIT	P1.7
LE4	BIT	P3.3
LE5	BIT	P3.4
LE6	BIT	P3.5
LE7	BIT	P3.6
BLANK	BIT	P1.4	;bit BLANK umo��uje zhasnut� cel�ho displeje (aktivn� v L)
TEST	BIT	P3.7	;bit TEST umo��uje zobrazit na v�ech pozic�ch displeje 8 (aktivn� v L)
DT	BIT	P0.7	;bit DT umo��uje zobrazit desetinn� te�ky na SEG2 a SEG4 (aktivn� v L)


START:	CLR EA
	CLR BLANK
	CALL DELAY
	CALL DELAY
	CALL DELAY
	JNB RESET,TES3	;servisn� nastaven�
	JNB SETING,TEST2;podr�en�m tla��tka se po RST spust� tr�ninkov� sekvence pro displej
	jmp st109
TEST3:	CLR BLANK	;zatemn�n� displeje
	MOV R0,#10
TEST4:	CLR TEST	;test displeje po zapnut� hodin
	CLR DT
	CALL DELAY
	CALL DELAY
	CALL DELAY
	SETB TEST
	SETB DT
	CALL DELAY
	CALL DELAY
	CALL DELAY
	DJNZ R0,TEST4
	CLR BLANK	;aktivace displeje
	JMP ST109
TEST2:	CALL TESTUJ	;tr�ninkov� sekvence pro displej
	JMP TEST3


;-------------------------------------------------------------------------
;zde program pokra�uje po p�ipojen� nap�jen�
ST109:	SETB ADJUST	;hodiny b��
	SETB TIME	;bit ur�uje, zda se zobrazuje �as nebo datum
	CLR DATUM	;datum bylo nastaveno
	CALL PER_DOB	;implicitn� hodnoty periody a doby zobrazen� datumu
	SETB EX0	;povolen� extern�ho p�eru�en� EX0 (viz registr IE), pin P3.2
	SETB IT0	;p�eru�en� bude spou�t�no saestupnou hranou (viz TCON)
	SETB EA		;povolen� v�ech p�eru�en�
	JMP N4		;skok p��mo na na test tla��tek

;-------------------------------------------------------------------------------------
;Zde program pokra�uje po resetu hodin (podr�en� RESET p�ed p�ipojen�m nap�jen�)
;Nastaven� p�eru�ovac�ho syst�mu 8051 a pomocn�ch registr�

TES3:	JNB RESET,$	;pozdr�en� b�hu p�i dr�en� tla��tka RESET
	CALL DELAY	;eliminace z�kmit� tla��tka
	CLR EA		;v�echna p�eru�en� zak�z�na
	SETB EX0	;povolen� extern�ho p�eru�en� EX0 (viz registr IE), pin P3.2
	SETB IT0	;p�eru�en� bude spou�t�no saestupnou hranou (viz TCON)
	CLR ADJUST	;hodiny neb��, bude t�eba je znovu nastavit
	SETB DATUM	;datum nebylo nastaveno
	CLR TIME
	CALL PER_DOB	;na�te implicitn� hodnoty konstant pro p�ep�n�n� �as/datum
	JMP REG_RTC

;Podprogram PER_DOB nastavuje implicitn� hodnoty periody a doby zobrazen� datumu

PER_DOB:MOV PER,#30	;hodnota je v sekund�ch (perioda zobrazov�n�)
	MOV DOBA,#5	;hodnota je v sekund�ch (doba zobrazov�n� datumu)
	MOV PER_D,PER	;definice obsahu p�echodn�ch registr�
	MOV DOBA_D,DOBA
	RET
;---------------------------------------------------------------------
;Po��te�n� inicializace obvodu
;Po t�to procedu�e jsou generov�ny pulzy INT na v�stupu STD.P (pin 1)
;s periodou 1 s a ve v�ech t�ech speci�ln�ch registrech RTC jsou nastavena pot�ebn� data
;Nastaven� registr� F, E a D v RTC (viz manu�l k RTC - str. 14)
;p�i z�pisu do konfigura�n�ch registr� nen� nutn� testovat sign�l BUSY

	;z�pis do registru F
REG_RTC:MOV I_O,#01011111B	;RESET obvodu
	CLR WRT			;TEST = 0, 24/12 = 1, STOP = 0, RESET = 1
	SETB WRT		;z�pis dat do registru F

	MOV I_O,#01011111B	;nastaven� cyklu 24/12 hod
	CLR WRT			;TEST = 0, 24/12 = 1, STOP = 0, RESET = 1
	SETB WRT		;z�pis dat do registru F

	MOV I_O,#01001111B	;odblokov�n� obvodu
	CLR WRT			;TEST = 0, 24/12 = 1, STOP = 0, RESET = 0
	SETB WRT		;z�pis dat do registru F

	;z�pis do registru E (nutn� p�i vyu��v�n� sign�lu STD.P - pin 1 RTC)
	MOV I_O,#01001110B	;adresa a data registru E
	CLR WRT			;t1 = 0, t2 = 1, ITRPT/STND = 0, MASK = 0
	SETB WRT		;nastaven re�im Fixed period pulse output mode

;V tomto m�st� ji� jsou na pinu 1 RTC generov�ny p�eru�ovac� pulzy s trv�n�m
;asi 8 ms a periodou 1 s

	;z�pis do registru D
	MOV I_O,#01001101B	;adresa a data registru D
	CLR WRT			;30sADJ = 0, IRQ FLAG = 1, BUSY = 0, HOLD = 0
	SETB WRT

	;z�pis do registru F - zastaven� a reset ��ta�e
	MOV I_O,#01111111B	;zastaven� a RESET ��ta�e v obvodu RTC
	CLR WRT			;TEST = 0, 24/12 = 1, STOP = 1, RESET = 1
	SETB WRT		;z�pis dat do registru F

;----------------------------------------------------------------------------

;Sekvence pro v�choz� stav nastavov�n� datumu (blik� �daj 01.01.16)

N20:	CLR EA		;z�kaz p�eru�en�
	CLR ADJUST	;nejsou nastavena ��dn� data
	SETB DATUM	;jako 1. se bude nastavovat datum a den v t�dnu
	MOV DEN,#0	;registr ��sla dne v t�dnu (0 = ned�le)
	MOV ROKY,#16	;registr rok�
	MOV MESICE,#1	;registr m�s�c�
	MOV DNY,#1	;registr dn�
	CALL BCD_DNY	;tyto podprogramy z�rove� pln� videoRAM
	CALL BCD_MES
	CALL BCD_ROK
	MOV DEN_TYD,DEN
	CALL DISPLEJ
	CLR DT		;desetinn� te�ky p�i zobrazen� datumu aktivn�
	JNB RESET,$	;nutn�, jinak po RST tla��tkem RESET nebude displej blikat
	CALL DELAY	;potla�en� z�kmit� p�i povolen� tla��tka
;------------------------------------------------------------------------
;Testov�n� stisku tla��tka RESET. Nen�-li stisknuto, sekvence testov�n�
;se opakuje a na displeji blik� �daj 01.01.16 (implicitn� v�choz� datum)

RYCH:	JNB RESET,DAT1	;stisknuto tla��tko RESET?
	CALL DELAY	;zpo�d�n� asi 65 ms
	CALL DELAY
	JNB RESET,DAT1	;tla��tko se testuje opakovan�
	CALL DELAY	;aby byla jeho reakce dostate�n� rychl�
	CALL DELAY
	JNB RESET,DAT1
	CALL DELAY
	CALL DELAY
	JNB RESET,DAT1
	CPL BLANK	;zatem�ovac� pulzy pro displej (aktivn� v L)
	JMP RYCH
;---------------------------------------------------------------------------

DAT1:	CALL DELAY	;potla�en� z�kmit� tla��tka
	JNB RESET,$	;ochrana p�ed trval�m dr�en�m tla��tka
	SETB BLANK	;aktivace displeje (konec blik�n�)
	CLR ADJUST	;informace pro syst�m, �e nen� nastaven platn� datum a �as
	SETB DATUM	;jako prvn� se bude nastavovat datum


;---------------------------------------------------------------------
;H L A V N �   P R O G R A M O V �   S M Y � K A
;Cyklus pro opakovan� �ten� 6 nastavovac�ch tla��tek.
;Jedn� se o hlavn� programovou smy�ku p�i b��c�ch hodin�ch,
;kter� je 1x za 1s p�eru�ov�na sign�lem z RTC

N4:	JNB SETING,N10		;tla��tko SET - po jeho 1.stisku dojde k zaps�n� datumu, 2. stisk = z�pis �asu
	JNB NAS_HOD,MEZI_N1	;tla��tko pro nastavov�n� hodin, resp. dn�
	JNB NAS_MIN,MEZI_N2	;tla��tko pro nastavov�n� minut, resp. m�s�c�
	JNB NAS_SEK,MEZI_N3	;tla��tko pro nastavov�n� sekund, resp. rok�
	JNB RESET,$		;tla��tko RESET - ��dn� reakce
	JNB TIM_DAT,N5		;tla��tko pro p�ep�n�n� zobrazen� �as/datum
	JMP N4

;Sekvence pro okam�it� zobrazen� datumu stiskem p��slu�n�ho tla��tka

N5:	CLR TIME		;p�ep�nac� bit pro re�im zobrazen� DATUM/�AS
	CLR DT			;aktivace desetinn�ch te�ek
	JNB TIM_DAT,$		;tato smy�ka je p�eru�ov�na INT0
	SETB TIME		;bude se znovu zobrazovat �as
	SETB DT			;vypnut� desetinn�ch te�ek
	JMP N4
;-------------------------------------------------------------------------------
;Reakce na stisky jednotliv�ch tla��tek s ohledem na p��znakov� bity

;Reakce na tla��tko SETING
N10:	JB ADJUST,N4		;je-li provedeno nastaven� hodin, ned�lej nic a testuj tla��tka
	JB DATUM,ZAP_DAT	;je-li nastaven p��znak DATUM, prove� z�pis data do 8051 (nikoliv RTC)
	JMP ZAP_TIM		;zapi� nastaven� �as, spus� hodiny a jdi na test tla��tek
;----------------------------------------------------------------------------------
CEK1:	CALL DELAY		;prodleva pro eliminaci z�kmit� tla��tka
	CALL NULY		;napln� videoRAM 0 (implicitn� �as je 00.00.00)
	CALL DISPLEJ		;zobrazen� implicitn�ho �asu na displeji
	SETB DT			;vypnut� desetinn�ch te�ek a zobrazen� dvojte�ek
	JNB SETING,$
	CALL DELAY		;potla�en� z�kmit� tla��tka p�i jeho uvoln�n�
	MOV HOD,#0		;v�choz� nastaven� pomocn�ch registr�
	MOV MIN,#0		;pro n�sleduj�c� nastavov�n� �asu
	MOV SEK,#0
	JMP N4			;jdi zp�tky na test tla��tek
;-----------------------------------------------------------------------------------
MEZI_N1:JMP N1
MEZI_N2:JMP N2
MEZI_N3:JMP N3			;pomocn� meziskoky, proto�e n�v�t� jsou daleko
;-----------------------------------------------------------------------------------

;Ulo�en� nov� nastaven�ho datumu a dne v t�dnu do p��slu�n�ch registr�,
;kter� pou��v� podprogram ZAPIS.

ZAP_DAT:CLR DATUM		;st�hnut� vlajky, d�le se budou nastavovat �asov� �daje
	MOV W_NEW,DEN_TYD	;nov� den v t�dnu (0 je ned�le)
	MOV Y10_NEW,SEK_DES	;nov� des�tky let (0 a� 9)
	MOV Y1_NEW,SEK_JED	;nov� jednotky let (0 a� 9)
	MOV M10_NEW,MIN_DES	;nov� des�tky m�s�c� (0 nebo 1)
	MOV M1_NEW,MIN_JED	;nov� jednotky m�s�c� (0 a� 9)
	MOV D10_NEW,HOD_DES	;nov� des�tky dn� (0 a� 3)
	MOV D1_NEW,HOD_JED	;nov� jednotky dn� (0 a� 9)
	CLR ADJUST		;nen� nastaven �as
	JMP CEK1		;pokra�uj v aktualizaci �asu

;Ulo�en� nov� nastaven�ch �asov�ch �daj� do registr�,
;kter� vyu��v� podprogram ZAPIS.

ZAP_TIM:MOV S1_NEW,SEK_JED
	MOV S10_NEW,SEK_DES
	MOV MI1_NEW,MIN_JED
	MOV MI10_NEW,MIN_DES
	MOV H1_NEW,HOD_JED
	MOV H10_NEW,HOD_DES
	CALL ZAPIS		;zap�e data do registr� RTC
	MOV I_O,#01001111B	;odblokuje �asom�ru v registru F, STOP = 0 a RESET = 0
	CLR WRT			;TEST = 0, 24/12 = 1, STOP = 0, RESET = 0
	SETB WRT		;z�pis dat do registru F - SPU�T�N� RTC
	SETB ADJUST	;bit indikuje nastaven� hodin a jejich norm�ln� provoz
	SETB TIME	;implicitn� se zobrazuje �as, datum na vy��d�n� tla��tkem
	SETB EA		;povolen� p�eru�en� - norm�ln� b�h hodin
	JMP N4		;zp�tky na test tla��tek


;------------------------------------------------------------------
;Nastaven� hodin nebo dn�

N1:	JB ADJUST,H14	;jestli�e RTC b��, nen� mo�no upravovat �as ani datum
	JB DATUM,H11	;za��n� se nastaven�m data
	INC HOD		;je-li nastaveno datum, nastavuje se �as
	MOV R6,HOD
	CJNE R6,#24,H13	;kontrola maxim�ln� hodnoty (23 hodin)
	MOV HOD,#0
H13:	CALL BCD_HOD
	CALL DISPLEJ
	CALL DELAY	;ur�uje rychlost p�i��t�n� p�i dr�en� tla��tka
	CALL DELAY
	CALL DELAY
	CALL DELAY
H14:	JMP N4

;Nastaven� dn�

H11:	INC DNY
	MOV R6,DNY
	CJNE R6,#32,H12	;kontrola maxim�ln� hodnoty (31 dn�)
	MOV DNY,#1	;do�lo k p�ete�en� registru dn�
	INC DEN		;zvy� ��slo dne v t�dnu
	MOV R5,DEN
	CJNE R5,#7,H12	;test na p�ete�en� registru dne v t�dnu (max. je 6)
	MOV DEN,#0
H12:	CALL BCD_DNY
	MOV DEN_TYD,DEN
	CALL DISPLEJ
	CALL DELAY	;ur�uje rychlost p�i��t�n� p�i dr�en� tla��tka
	CALL DELAY
	CALL DELAY
	JMP N4
;-------------------------------------------------------------------------
;Nastaven� minut nebo m�s�c�

N2:	JB ADJUST,MEZ_N4;jestli�e RTC b��, nen� mo�no upravovat �as ani datum
	JB DATUM,K22
	INC MIN
	MOV R6,MIN
	CJNE R6,#60,K1	;kontrola maxim�ln� hodnoty (59 minut)
	MOV MIN,#0
K1:	CALL BCD_MIN
	CALL DISPLEJ
	CALL DELAY
	CALL DELAY
	CALL DELAY
	CALL DELAY
	JMP N4

;Nastaven� m�sic�

K22:	INC MESICE
	MOV R6,MESICE
	CJNE R6,#13,H19	;kontrola maxim�ln� hodnoty (12 m�s�c�)
	MOV MESICE,#1	;do�lo k p�ete�en� registru dn�
H19:	CALL BCD_MES
	CALL DISPLEJ
	CALL DELAY	;ur�uje rychlost p�i��t�n� p�i dr�en� tla��tka
	CALL DELAY
	CALL DELAY
MEZ_N4:	JMP N4
;------------------------------------------------------------------------------
;Nastaven� sekund nebo rok�

N3:	JB ADJUST,MEZI_N4	;jestli�e RTC b��, nen� mo�no upravovat �as ani datum
	JB DATUM,K33
	INC SEK
	MOV R6,SEK
	CJNE R6,#60,K2	;kontrola maxim�ln� hodnoty (59 sekund)
	MOV SEK,#0
K2:	CALL BCD_SEK
	CALL DISPLEJ
	CALL DELAY
	CALL DELAY
	CALL DELAY
	CALL DELAY
MEZI_N4:JMP N4

;Nastaven� rok�

K33:	INC ROKY
	MOV R6,ROKY
	CJNE R6,#51,H15	;kontrola maxim�ln� hodnoty (rok 2050)
	MOV ROKY,#16	;do�lo k p�ete�en� registru dn�
H15:	CALL BCD_ROK
	CALL DISPLEJ
	CALL DELAY	;ur�uje rychlost p�i��t�n� p�i dr�en� tla��tka
	CALL DELAY
	CALL DELAY
	JMP N4

;-------------------------------------------------------------------------------

;Podprogram BCD_HOD vytvori z binarn. cisla ulozeneho v registru HOD
;cislo dekadicke, jehoz nizsi rad (jednotky) bude ulozen na adrese HOD_JED
;a vyssi rad (desitky) na adrese HOD_DES.
;
;Pouziva: ACC, B, R1
;Vstup: binarni cislo v registru HOD
;Vystup: dekadicka cisla v pameti videoRAM

BCD_HOD: PUSH 01H
         PUSH B
         PUSH ACC
         MOV A,HOD
	 MOV B,#10
         DIV AB
         MOV HOD_DES,A		;vy��� ��d
         MOV HOD_JED,B		;ni��� ��d
         POP ACC
         POP B
         POP 01H
         RET

;Podprogram BCD_MIN vytvori z binarn. cisla ulozeneho v registru MIN
;cislo dekadicke, jehoz nizsi rad (jednotky) bude ulozen na adrese MIN_JED
;a vyssi rad (desitky) na adrese MIN_DES.
;
;Pouziva: ACC, B, R1
;Vstup: binarni cislo v registru MIN
;Vystup: dekadicka cisla v pameti videoRAM

BCD_MIN: PUSH 01H
         PUSH B
         PUSH ACC
         MOV A,MIN
	 MOV B,#10
         DIV AB
         MOV MIN_DES,A		;vy��� ��d
         MOV MIN_JED,B		;ni��� ��d
         POP ACC
         POP B
         POP 01H
         RET

;Podprogram BCD_SEK vytvori z binarn. cisla ulozeneho v registru SEK
;cislo dekadicke, jehoz nizsi rad (jednotky) bude ulozen na adrese SEK_JED
;a vyssi rad (desitky) na adrese SEK_DES.
;
;Pouziva: ACC, B, R1
;Vstup: binarni cislo v registru SEK
;Vystup: dekadicka cisla v pameti videoRAM

BCD_SEK: PUSH 01H
         PUSH B
         PUSH ACC
         MOV A,SEK
	 MOV B,#10
         DIV AB
         MOV SEK_DES,A		;vy��� ��d
         MOV SEK_JED,B		;ni��� ��d
         POP ACC
         POP B
         POP 01H
         RET

;Podprogram BCD_DNY vytvori z binarn. cisla ulozeneho v registru DNY
;cislo dekadicke, jehoz nizsi rad (jednotky) bude ulozen na adrese HOD_JED
;a vyssi rad (desitky) na adrese HOD_DES (pozice sispleje jsou sd�len�
;pro �asov� a datov� �daj).
;
;Pouziva: ACC, B, R1
;Vstup: binarni cislo v registru DNY
;Vystup: dekadicka cisla v pameti videoRAM

BCD_DNY: PUSH 01H
         PUSH B
         PUSH ACC
         MOV A,DNY
	 MOV B,#10
         DIV AB
         MOV HOD_DES,A		;vy��� ��d
         MOV HOD_JED,B		;ni��� ��d
         POP ACC
         POP B
         POP 01H
         RET

;Podprogram BCD_MES vytvori z binarn. cisla ulozeneho v registru MESICE
;cislo dekadicke, jehoz nizsi rad (jednotky) bude ulozen na adrese MIN_JED
;a vyssi rad (desitky) na adrese MIN_DES (pozice sispleje jsou sd�len�
;pro �asov� a datov� �daj).
;
;Pouziva: ACC, B, R1
;Vstup: binarni cislo v registru MESICE
;Vystup: dekadicka cisla v pameti videoRAM

BCD_MES: PUSH 01H
         PUSH B
         PUSH ACC
         MOV A,MESICE
	 MOV B,#10
         DIV AB
         MOV MIN_DES,A		;vy��� ��d
         MOV MIN_JED,B		;ni��� ��d
         POP ACC
         POP B
         POP 01H
         RET

;Podprogram BCD_ROK vytvori z binarn. cisla ulozeneho v registru ROKY
;cislo dekadicke, jehoz nizsi rad (jednotky) bude ulozen na adrese SEK_JED
;a vyssi rad (desitky) na adrese SEK_DES (pozice sispleje jsou sd�len�
;pro �asov� a datov� �daj).
;
;Pouziva: ACC, B, R1
;Vstup: binarni cislo v registru ROKY
;Vystup: dekadicka cisla v pameti videoRAM

BCD_ROK: PUSH 01H
         PUSH B
         PUSH ACC
         MOV A,ROKY
	 MOV B,#10
         DIV AB
         MOV SEK_DES,A		;vy��� ��d
         MOV SEK_JED,B		;ni��� ��d
         POP ACC
         POP B
         POP 01H
         RET

;Podprogram NULY napn� videoRAM sam�mi nulami.

NULY:	MOV SEK_JED,#0
	MOV SEK_DES,#0
	MOV MIN_JED,#0
	MOV MIN_DES,#0
	MOV HOD_JED,#0
	MOV HOD_DES,#0
	MOV DEN_TYD,#0AH		;7. pozice je potm�
	RET

;Podprogram DELAY ur�uje rychlost p�i��t�n� �daj� na displeji
;p�i ru�n�m zad�v�n� �daj�. M� zpo�d�n� asi 65 ms

DELAY:	MOV TMOD,#01H
	MOV TL0,#0
	MOV TH0,#0
	SETB TR0
	JNB TF0,$
	CLR TR0
	CLR TF0
	RET

;Podprogram DEL vyu��v� rutina kontroly displeje

DEL:	MOV R0,#3
DEL1:	CALL DELAY
	DJNZ R0,DEL1
	RET
;------------------------------------------------------------------------
;Podprogram ZAPIS napln� jednotliv� �asov� registry aktu�ln�mi daty.
;Pln� rovn� registry datumu a dne v t�dnu.
;P��stup k datov�m registr�m je podm�n�n stavem BUSY=0!

ZAPIS:	PUSH 00H
	PUSH 01H
	PUSH ACC
	MOV R0,#0		;registr adresy registru v RTC
	MOV R1,#S1_NEW		;v R1 je adresa registru jenotek sekund v RAM
Z1:	MOV A,@R1		;hodnota na p��slu�n� adrese do ACC
	SWAP A			;data jsou v horn� polovin� registru
	ANL A,#11110000B	;vymaskov�n� doln� poloviny registru pro adresu
	ORL A,R0		;sdru�en� adresy a dat
	MOV I_O,A
	CLR WRT			;z�pis �daje do registru
	SETB WRT
	INC R0			;zv��en� adresy registru v RTC o 1
	INC R1			;zv��en� adresy v RAM o 1
	CJNE R0,#0DH,Z1		;kontrola, zda byly zaps�ny v�echny registry
	POP ACC
	POP 01H
	POP 00H
	RET

;-----------------------------------------------------------------
;EXTERN� P�ERU�EN�
;Podprogram CTENI je obslu�n� rutina extern�ho p�eru�en� INT0.
;Toto p�eru�en� je vyvol�no ka�dou sekundu sign�lem RTC STD.P
;Program CTENI napln� registry videoRAM v 8051 daty na�ten�mi z registr� RTC
;Prvn� ��st vy��t� pouze aktu�ln� �as.

CTENI:	JB DAT_TIM,CT6	;sp�na� nen� sepnut�, zobrazuje se trvale �as
	CALL PREP	;podprogram nastavuje, resp. nuluje bit TIME
CT6:	SETB RDG
	PUSH 00H
	PUSH 01H
	PUSH ACC
	MOV R0,#0	;adresa registru v RTC pro jednotky sekund
	MOV R1,#S1	;adresa registru pro jednotky sekund v 8051
CT1:	MOV A,R0
	ORL A,#0F0H	;horn� 4 bity (data) mus� b�t v 1 (jako vstup)
	MOV I_O,A	;adresa �ten�ho registru na RTC
	CLR RDG		;�ten� registru
	MOV A,I_O	;stav portu do ACC
	SETB RDG	;konec �tec�ho pulzu
	SWAP A		;prohozen� spodn� a horn� �tve�ice bit�
	ANL A,#0FH	;vymaskov�n� dat
	MOV @R1,A	;data do p��slu�n�ho registru v 8051
	INC R0		;zv��en� adresy RTC
	INC R1		;posun na dal�� registr
	CJNE R0,#6,CT1	;test, zda byly na�teny v�echny �asov� �daje

;Druh� ��st plynule navazuje na ��st p�edchoz� a vy��t� z RTC �daje
;o datu a dnu v t�dnu.
;0 = ned�le, 1 = pond�l� ....6 = sobota

	MOV R1,#DEN1	;adresa v RAM 8051 pro jednotky dn�
CT2:	MOV A,R0
	ORL A,#0F0H	;horn� 4 bity mus� b�t v 1 (jako vstup)
	MOV I_O,A	;adresa �ten�ho registru na RTC
	CLR RDG		;�ten� registru
	MOV A,I_O	;stav portu do ACC
	SETB RDG
	SWAP A
	ANL A,#0FH	;vymaskov�n� dat
	MOV @R1,A	;data do videopam�ti
	INC R0
	INC R1		;posun na vy��� ��d ve videopam�ti
	CJNE R0,#0DH,CT2
	POP ACC
	POP 01H
	POP 00H
	MOV I_O,#01001101B	;adresa a data registru D
	CLR WRT			;30sADJ = 0, IRQ FLAG = 1, BUSY = 0, HOLD = 0
	SETB WRT
	JNB TIME,CT3	;bude se zobrazovat datum
	CALL VID_TIM	;bude se zobrazovat �as
	SETB DT
	JMP CT4
CT3:	CLR DT
	CALL VID_DAT
CT4:	CALL DISPLEJ
	RETI
;---------------------------------------------------------------------------

;Podprogram PREP nastavuje, resp. nuluje bit TIME. Obsah registru PER
;ur�uje periodu, s kterou se bude na displeji automaticky zobrazovat
;aktu�ln� datum a den v t�dnu. Obsah registru DOBA ur�uje, jak dlouho
;bude trvat zobrazen� datumu. Po uplynut� t�to doby se syst�m znovu
;automaticky vr�t� k zobrazov�n� aktu�ln�ho �asu. Tato funkce mus� b�t
;povolena u�ivatelem p�epnut�m p�ep�na�e DAT_TIM!
;Podprogram je vol�n pouze obslu�nou rutinou p�eru�en� CTENI

PREP:	JNB TIME,PR2
	DJNZ PER_D,PR1
	CLR TIME
	MOV PER_D,PER	;obnoven� implicitn� hodnoty
	JMP PR1
PR2:	DJNZ DOBA_D,PR1
	SETB TIME
	MOV DOBA_D,DOBA	;obnoven� implicitn� hodnoty
PR1:	RET

;Podprogram VID_TIM napln� videoRAM 8051 �asov�mi �daji

VID_TIM:MOV SEK_JED,S1	;jedn� se o adresy 7mi segmentovek
	MOV SEK_DES,S10
	MOV MIN_JED,MI1
	MOV MIN_DES,MI10
	MOV HOD_JED,H1
	MOV HOD_DES,H10
	MOV DEN_TYD,#0AH	;7. pozice p�i zobrazen� �asu nesv�t�
	RET

;Podprogram VID_DAT napln� videoRAM 8051 �daji o datumu a
;dnu v t�dnu

VID_DAT:MOV SEK_JED,ROK1	;jedn� se o adresy 7mi segmentovek
	MOV SEK_DES,ROK10
	MOV MIN_JED,MES1
	MOV MIN_DES,MES10
	MOV HOD_JED,DEN1
	MOV HOD_DES,DEN10
	MOV DEN_TYD,DEN_W
	RET

;-----------------------------------------------------------------------------
;Podprogram DISPLEJ vy�le data z pam�ti videoRAM na displej

DISPLEJ:PUSH ACC
	CLR BLANK
	SETB TEST
	SETB LE1
	SETB LE2
	SETB LE3
	SETB LE4
	SETB LE5
	SETB LE6
	SETB LE7
	MOV A,P1
	ANL A,#0F0H
	ORL A,HOD_DES
	MOV P1,A
	CLR LE1
	SETB LE1
	MOV A,P1
	ANL A,#0F0H
	ORL A,HOD_JED
	MOV P1,A
	CLR LE2
	SETB LE2
	MOV A,P1
	ANL A,#0F0H
	ORL A,MIN_DES
	MOV P1,A
	CLR LE3
	SETB LE3
	MOV A,P1
	ANL A,#0F0H
	ORL A,MIN_JED
	MOV P1,A
	CLR LE4
	SETB LE4
	MOV A,P1
	ANL A,#0F0H
	ORL A,SEK_DES
	MOV P1,A
	CLR LE5
	SETB LE5
	MOV A,P1
	ANL A,#0F0H
	ORL A,SEK_JED
	MOV P1,A
	CLR LE6
	SETB LE6
	MOV A,P1
	ANL A,#0F0H
	ORL A,DEN_TYD
	MOV P1,A
	CLR LE7
	SETB LE7
	POP ACC
	SETB BLANK
	RET

;-----------------------------------------------------------------------
;Podprogram TESTUJ prov�d� test displeje.
;Mus� sv�tit (blikat) v�echny segmenty, desetinn� te�ky a dvojte�ky.
;Kontrolu prov�d� vizu�ln� u�ivatel.

TESTUJ:	CALL ROT_1
	CALL ROT_2
	CALL ROT_3
	CALL ROT_4
	CALL ROT_5
	CALL ROT_6
	CALL ROT_7
RR_8:	MOV SEK_JED,#0FFH
	MOV SEK_DES,#0FFH	;segmentovky nesv�t�
	MOV MIN_JED,#0FFH
	MOV MIN_DES,#0FFH
	MOV HOD_JED,#0FFH
	MOV HOD_DES,#0FFH
	MOV DEN_TYD,#0FFH
	CALL DELAY
	CALL DELAY
	CALL DELAY
	CALL DISPLEJ
	MOV R1,#16
RR_9:	CPL DT
	CALL DELAY
	CALL DELAY
	CALL DELAY
	DJNZ R1,RR_9
	MOV R1,#15
RR_1:	CALL DELAY
	CLR BLANK
	CPL TEST
	CALL DELAY
	SETB BLANK
	DJNZ R1,RR_1
	CALL D1_6
	CALL DELAY
	CALL DELAY
	CALL DELAY
	MOV R1,#3
RR_10:	CALL D1_7
	CALL DEL
	CALL D1_8
	CALL DEL
	CALL D1_9
	CALL DEL
	CALL D1_10
	CALL DEL
	CALL D1_11
	CALL DEL
	CALL D1_12
	CALL DEL
	CALL D1_13
	CALL DEL
	CALL D1_14
	CALL DEL
	CALL D1_15
	CALL DEL
	CALL D1_16
	CALL DEL
	CALL D1_17
	CALL DEL
	DJNZ R1,RR_10
	JNB SETING,$	;ochrana p�es dr�en�m tla��tka
	CALL DELAY
	RET		;konec podprogramu TESTUJ

;Kontrola 1. segmentovky

ROT_1:	MOV R1,#0
	MOV SEK_JED,#0FFH
	MOV SEK_DES,#0FFH	;segmentovka nesv�t�
	MOV MIN_JED,#0FFH
	MOV MIN_DES,#0FFH
	MOV HOD_JED,#0FFH
	MOV HOD_DES,#0
	MOV DEN_TYD,#0FFH
ROT_11:	CALL DISPLEJ
	CALL DELAY
	CALL DELAY
	INC HOD_DES
	INC R1
	CJNE R1,#10,ROT_11
	RET

;Kontrola 1. + 2. segmentovky

ROT_2:	MOV R1,#0
	MOV SEK_JED,#0FFH
	MOV SEK_DES,#0FFH	;segmentovka nesv�t�
	MOV MIN_JED,#0FFH
	MOV MIN_DES,#0FFH	;segmentovka nesv�t�
	MOV HOD_JED,#0
	MOV HOD_DES,#0
	MOV DEN_TYD,#0FFH
ROT_12:	CALL DISPLEJ
	CALL DELAY
	CALL DELAY
	INC HOD_DES
	INC HOD_JED
	INC R1
	CJNE R1,#10,ROT_12
	RET

;Kontrola 1. + 2. + 3. segmentovky

ROT_3:	MOV R1,#0
	MOV SEK_JED,#0FFH
	MOV SEK_DES,#0FFH	;segmentovka nesv�t�
	MOV MIN_JED,#0FFH
	MOV MIN_DES,#0
	MOV HOD_JED,#0
	MOV HOD_DES,#0
	MOV DEN_TYD,#0FFH
ROT_13:	CALL DISPLEJ
	CALL DELAY
	CALL DELAY
	INC MIN_DES
	INC HOD_DES
	INC HOD_JED
	INC R1
	CJNE R1,#10,ROT_13
	RET

;Kontrola 1. + 2. + 3. + 4. segmentovky

ROT_4:	MOV R1,#0
	MOV SEK_JED,#0FFH
	MOV SEK_DES,#0FFH	;segmentovka nesv�t�
	MOV MIN_JED,#0
	MOV MIN_DES,#0
	MOV HOD_JED,#0
	MOV HOD_DES,#0
	MOV DEN_TYD,#0FFH
ROT_14:	CALL DISPLEJ
	CALL DELAY
	CALL DELAY
	INC MIN_JED
	INC MIN_DES
	INC HOD_DES
	INC HOD_JED
	INC R1
	CJNE R1,#10,ROT_14
	RET

;Kontrola 1. + 2. + 3. + 4. + 5. segmentovky

ROT_5:	MOV R1,#0
	MOV SEK_JED,#0FFH
	MOV SEK_DES,#0
	MOV MIN_JED,#0
	MOV MIN_DES,#0
	MOV HOD_JED,#0
	MOV HOD_DES,#0
	MOV DEN_TYD,#0FFH
ROT_15:	CALL DISPLEJ
	CALL DELAY
	CALL DELAY
	INC SEK_DES
	INC MIN_JED
	INC MIN_DES
	INC HOD_DES
	INC HOD_JED
	INC R1
	CJNE R1,#10,ROT_15
	RET

;Kontrola 1. + 2. + 3. + 4. + 5. + 6. segmentovky

ROT_6:	MOV R1,#0
	MOV SEK_JED,#0
	MOV SEK_DES,#0
	MOV MIN_JED,#0
	MOV MIN_DES,#0
	MOV HOD_JED,#0
	MOV HOD_DES,#0
	MOV DEN_TYD,#0FFH
ROT_16:	CALL DISPLEJ
	CALL DELAY
	CALL DELAY
	INC SEK_JED
	INC SEK_DES
	INC MIN_JED
	INC MIN_DES
	INC HOD_DES
	INC HOD_JED
	INC R1
	CJNE R1,#10,ROT_16
	RET

;Kontrola 1. + 2. + 3. + 4. + 5. + 6. + 7. segmentovky

ROT_7:	MOV R1,#0
	MOV SEK_JED,#0
	MOV SEK_DES,#0
	MOV MIN_JED,#0
	MOV MIN_DES,#0
	MOV HOD_JED,#0
	MOV HOD_DES,#0
	MOV DEN_TYD,#0
ROT_17:	CALL DISPLEJ
	CALL DELAY
	CALL DELAY
	INC DEN_TYD
	INC SEK_JED
	INC SEK_DES
	INC MIN_JED
	INC MIN_DES
	INC HOD_DES
	INC HOD_JED
	INC R1
	CJNE R1,#10,ROT_17
	RET

D1_6:	MOV SEK_JED,#6
	MOV SEK_DES,#5
	MOV MIN_JED,#4
	MOV MIN_DES,#3
	MOV HOD_JED,#2
	MOV HOD_DES,#1
	MOV DEN_TYD,#0FFH
	CALL DISPLEJ
	RET

D1_7:	MOV SEK_JED,#5
	MOV SEK_DES,#4
	MOV MIN_JED,#3
	MOV MIN_DES,#2
	MOV HOD_JED,#1
	MOV HOD_DES,#0FFH
	MOV DEN_TYD,#0FFH
	CALL DISPLEJ
	RET

D1_8:	MOV SEK_JED,#4
	MOV SEK_DES,#3
	MOV MIN_JED,#2
	MOV MIN_DES,#1
	MOV HOD_JED,#0FFH
	MOV HOD_DES,#0FFH
	MOV DEN_TYD,#0FFH
	CALL DISPLEJ
	RET

D1_9:	MOV SEK_JED,#3
	MOV SEK_DES,#2
	MOV MIN_JED,#1
	MOV MIN_DES,#0FFH
	MOV HOD_JED,#0FFH
	MOV HOD_DES,#0FFH
	MOV DEN_TYD,#0FFH
	CALL DISPLEJ
	RET

D1_10:	MOV SEK_JED,#2
	MOV SEK_DES,#1
	MOV MIN_JED,#0FFH
	MOV MIN_DES,#0FFH
	MOV HOD_JED,#0FFH
	MOV HOD_DES,#0FFH
	MOV DEN_TYD,#0FFH
	CALL DISPLEJ
	RET

D1_11:	MOV SEK_JED,#1
	MOV SEK_DES,#0FFH
	MOV MIN_JED,#0FFH
	MOV MIN_DES,#0FFH
	MOV HOD_JED,#0FFH
	MOV HOD_DES,#0FFH
	MOV DEN_TYD,#0FFH
	CALL DISPLEJ
	RET

D1_12:	MOV SEK_JED,#0FFH
	MOV SEK_DES,#0FFH
	MOV MIN_JED,#0FFH
	MOV MIN_DES,#0FFH
	MOV HOD_JED,#0FFH
	MOV HOD_DES,#0FFH
	MOV DEN_TYD,#0FFH
	CALL DISPLEJ
	RET

D1_13:	MOV SEK_JED,#0FFH
	MOV SEK_DES,#0FFH
	MOV MIN_JED,#0FFH
	MOV MIN_DES,#0FFH
	MOV HOD_JED,#0FFH
	MOV HOD_DES,#5
	MOV DEN_TYD,#0FFH
	CALL DISPLEJ
	RET

D1_14:	MOV SEK_JED,#0FFH
	MOV SEK_DES,#0FFH
	MOV MIN_JED,#0FFH
	MOV MIN_DES,#0FFH
	MOV HOD_JED,#5
	MOV HOD_DES,#4
	MOV DEN_TYD,#0FFH
	CALL DISPLEJ
	RET

D1_15:	MOV SEK_JED,#0FFH
	MOV SEK_DES,#0FFH
	MOV MIN_JED,#0FFH
	MOV MIN_DES,#5
	MOV HOD_JED,#4
	MOV HOD_DES,#3
	MOV DEN_TYD,#0FFH
	CALL DISPLEJ
	RET

D1_16:	MOV SEK_JED,#0FFH
	MOV SEK_DES,#0FFH
	MOV MIN_JED,#5
	MOV MIN_DES,#4
	MOV HOD_JED,#3
	MOV HOD_DES,#2
	MOV DEN_TYD,#0FFH
	CALL DISPLEJ
	RET

D1_17:	MOV SEK_JED,#0FFH
	MOV SEK_DES,#5
	MOV MIN_JED,#4
	MOV MIN_DES,#3
	MOV HOD_JED,#2
	MOV HOD_DES,#1
	MOV DEN_TYD,#0FFH
	CALL DISPLEJ
	RET

        END
