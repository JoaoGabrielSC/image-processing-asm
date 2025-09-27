;***************************************************************
; EP - Programa de Processamento Digital de Imagens
; Autor: João Gabriel Santos Custodio
; Engenharia Elétrica - UFES
; Turma 1
; Sistemas Embarcados I - 2025/1
;***************************************************************

..start:
		
mov ax,data
mov ds,ax
mov ax,stack
mov ss,ax
mov sp,stacktop


mov ah,0Fh                            
int 10h
mov [modo_anterior],al   

mov al,12h                           
mov ah,0
int 10h

;Inicia UI
mov byte[cor],branco_intenso
call criar_interface

; Inicia o mouse
mov ax,0
int 33h
mov ax,1
int 33h 
	
; Interrupção do mouse seguindo lógica do int 33h
; cx <- posição horizontal do último clique
; dx <- posição vertical do último clique
; bx <- # de cliques
; Se bx for zero, não houve clique, deve retornar
check_clique:
	mov ax,5              
	mov bx,0
	int 33h               
	cmp bx,0              
	jne tratar_clique
	jmp check_clique


;***************************************************************
; Referencia em (0,0) está na posição superior direita
tratar_clique:
cmp   dx, 90                                    
	jb    localiza_clique
	jmp   check_clique
	

; qual botão foi selecionado
localiza_clique:
	cmp cx,80 ;x <80, botão abrir
	jb botao_abrir
	cmp cx,160 ;x >80 e <160, botão sair
	jb botao_sair
	cmp cx,320 ;x >160 e <320, botão passa baixa
	jb botao_passa_baixa
	cmp cx,480 ;x >320 e <480, botão passa alta
	jb botao_passa_alta
	cmp cx,640 ;x >480 e <640, botão texto_gradiente
	jb botao_texto_gradiente
	jmp check_clique
	
botao_abrir:
	jmp botao_abrir2
botao_sair:
	jmp botao_sair2
botao_passa_baixa:
	jmp botao_passa_baixa2
botao_passa_alta:
	jmp botao_passa_alta2
botao_texto_gradiente:
	jmp botao_texto_gradiente2
	
; Deseja-se aplicar filtro texto_gradiente:
botao_texto_gradiente2:
	mov byte[cor],amarelo ; Muda a cor da mensagem 'texto_gradiente' para amarelo
	call text_texto_gradiente
	mov byte[cor],branco_intenso
	call text_sair
	call text_abrir
	call text_passa_baixa
	call text_passa_alta
	call text_identificacao

	; Apaga mouse para evitar do usuário clickar enquanto o filtro é aplicado
	mov ax,2h
	int 33h
	; Realiza o filtro texto_gradiente
	call filtro_texto_gradiente
	; Mostra mouse
	mov ax,1h
	int 33h 
	; Retorna para o cheque de ocorrência do clique do mouse
	jmp check_clique
		
; Deseja-se aplicar filtro passa-alta:
botao_passa_alta2:
	mov byte[cor],amarelo ; Muda a cor da mensagem 'passa-alta' para amarelo
	call text_passa_alta
	mov byte[cor],branco_intenso
	call text_sair
	call text_abrir
	call text_passa_baixa
	call text_texto_gradiente
	call text_identificacao
	mov ax,2h
	int 33h
	call filtro_passa_alta ; Realiza o filtro passa-alta
	; Mostra mouse novamente
	mov ax,1h
	int 33h 
	; Retorna para o cheque de ocorrência do clique do mouse
	jmp check_clique
	
; Deseja-se abrir o arquivo:
botao_abrir2:
	mov byte[cor],amarelo
	call text_abrir
	mov byte[cor],branco_intenso
	call text_sair
	call text_passa_baixa
	call text_passa_alta
	call text_texto_gradiente
	call text_identificacao
	mov ax,2h
	int 33h
	mov al,byte[aberto]     
	cmp al,0
	je  vai_abrir       
	call limpa_imagem_e
	;Fecha o arquivo
	mov bx,[file_handle]
	mov ah,3eh
	mov al,00h
	int 21h

; Abre o arquivo padrão imagem.txt
vai_abrir:
	call abre_arquivo
	mov ax,1h
	int 33h 
	jmp check_clique
	
	
; Deseja-se sair do programa:
botao_sair2:
	mov byte[cor],amarelo
	call text_sair
	mov byte[cor],branco_intenso
	call text_abrir
	call text_passa_baixa
	call text_passa_alta
	call text_texto_gradiente
	call text_identificacao
	jmp sair
	
; Deseja-se aplicar filtro passa-baixa:
botao_passa_baixa2:
	mov byte[cor],amarelo
	call text_passa_baixa
	mov byte[cor],branco_intenso
	call text_sair
	call text_abrir
	call text_passa_alta
	call text_texto_gradiente
	call text_identificacao
	; Apaga mouse para evitar do usuário clicar enquanto o filtro é aplicado
	mov ax,2h
	int 33h
	; Realiza o filtro passa-baixa
	call filtro_passa_baixa
	; Mostra mouse novamente
	mov ax,1h
	int 33h 
	; Retorna para o cheque de ocorrência do clique do mouse
	jmp check_clique
	

;***************************************************************
;
; BLOCO DE ABERTURA DE ARQUIVOS
;
;***************************************************************
abre_arquivo:
; Salva contexto
push cx     
push ax
push dx
push bx
;
; Abrir arquivo somente para leitura
mov ah,3dh        
mov al,00h
mov dx,file_name
int 21h
; file_handle grava um 'endereco' pra poder usar o arquivo
mov [file_handle],ax  
; Verifica se o arquivo foi aberto corretamente
lahf                
and ah,01           
cmp ah,01           
	jne abriu_corretamente          
;Caso contr�rio, retorna ao cheque de ocorr�ncia de clique
pop   bx
pop   dx
pop   ax    
pop   cx
ret
;
;Caso o arquivo tenha sido aberto corretamente, 
; sinaliza ao fazer [aberto] <- 1 
abriu_corretamente:
mov byte[aberto],1
leitura_arquivo:
	mov word[coluna_atual],0
	mov word[linha_atual],0
	mov word[bytes_lidos],0 ; Sinaliza quantos bytes válidos, != 20h, foram lidos

	mov cx,300

linhas:
	push cx
	mov cx,300
colunas:
	push cx
proximo_byte:
	mov bx,[file_handle]
	mov dx, buffer
	mov cx,1      ; quantidade de bytes a serem lidos: 1 char por vez
	mov ah,3Fh      ; 3Fh - l� o arquivo
	int 21h       ; executa fun��o em ah
	;Caso n�o seja lido 1 byte, chegou ao final do arquivo
	cmp ax,cx
		jne final_arquivo
	;Caso contr�rio, coloca em al valor do byte lido
	mov al, [buffer]
	mov [ascii],al
	;Caso o byte lido seja um espa�o, um novo pixel (n�mero) acabou de ser lido
	cmp al,20h
		je proximo_numero
	;Caso contr�rio, converte o byte lido para decimal e l� pr�ximo byte
	inc word[bytes_lidos]
	call asciiparadecimal
	jmp proximo_byte
	
proximo_numero:
	; Se o primeiro byte a ser lido for um espa�o,
	; ainda n�o h� n�mero para ser plotado
	cmp word[bytes_lidos],0
	je proximo_byte
	; Transforma os n�meros lidos em unidade, dezena e centena em um n�mero decimal
	call junta_digitos
	; Plota este n�mero na tela
	call plota_pixel
	inc word[coluna_atual]
	pop cx
	loop colunas
	dec word[linha_atual]
	mov word[coluna_atual],0
	pop cx
	loop linhas
	
final_arquivo:
	pop cx
	pop cx    
	mov word[linha_atual],0
	mov word[coluna_atual],0
		; Fecho o arquivo para que, na próxima vez que seja aberto,
		; o ponteiro volte ao início do arquivo.
	mov bx,[file_handle]
	mov ah,3eh
	mov al,00h
	int 21h

	; Libera a checagem de clique do mouse
	pop   bx
	pop   dx
	pop   ax    
	pop   cx
	ret

;***************************************************************
;
; FUNÇÕES PARA TRATAMENTO DE DADOS
;
;***************************************************************
;Plotar a imagem gerada a partir do filtro
plota_pixel_filtros:      
	push ax
	push bx
	push dx
	;
	; Correspod�ncia da cor de acordo com o valor 
	; do n�mero do pixel lido

	mov bl,16
	mov al,byte[current]
	xor ah,ah
	div bl   

	mov byte[cor],al
	mov bx,[coluna_atual]
	add bx,333
	push bx   ;x
	mov bx,[linha_atual]
	add bx,389
	push bx   ;y
	call plot_xy
	;
	pop dx
	pop bx
	pop ax
	ret

;***************************************************************
; Função que converte cada caracter significativo para decimal
asciiparadecimal:
	push ax
	push cx
	;
	xor cx,cx ; Zera CX com operador xor que é mais rápido que mov cx,0
	mov al,[ascii]
	sub al,30h
	mov cl, byte[unidade] 
	mov ch, byte[dezena] 
	
	mov byte[unidade],al  
	mov byte[dezena],cl  
	mov byte[centena],ch  

	pop cx
	pop ax
	ret

;***************************************************************
; Fun��o que gera um n�mero juntando os digitos,
; mutiplicando-os por seus respectivos valores de base
; e somando-os.
junta_digitos:  
	push ax
	push bx
	push cx
	;
	xor ah,ah
	xor ch,ch

	mov al,byte[centena]
	mov bl,100
	mul bl
	mov cx,ax 

	xor ah,ah
	mov al,byte[dezena]
	mov bl,10
	mul bl
	add cx,ax

	xor ah,ah
	mov al,[unidade]
	add cx,ax 

	mov byte[decimal],cl

	mov byte[unidade],0
	mov byte[dezena],0
	mov byte[centena],0
	pop   cx
	pop   bx
	pop   ax
	ret
	
;***************************************************************
;Mostra a imagem original com escala de 16 cores
plota_pixel:      
	push ax
	push bx
	push dx
	mov dl,16
	mov al,byte[decimal]
	xor ah,ah
	div dl   
	mov byte[cor],al
	mov bx,[coluna_atual]
	add bx,13
	push bx   ;x
	mov bx,[linha_atual]
	add bx,389
	push bx   ;y
	call plot_xy
	;
	pop dx
	pop bx
	pop ax
	ret 
		
;***************************************************************  
; Funçao usada para pintar a esquerda de preto pois o pixel
; na coluna 0 deve ser sempre preto
limpa_imagem_e:    
	push    cx     
	push    ax
	push    dx
	push    bx
	mov word[linha_atual],0
	mov word[coluna_atual],0
	mov cx,300

linhas2:
	push cx
	mov cx, 300

colunas2:
	call plota_pixel2
	inc word[coluna_atual]
	loop colunas2
	dec word[linha_atual]
	mov word[coluna_atual],0
	pop cx
	loop linhas2
	pop   bx
	pop   dx
	pop   ax    
	pop   cx
	ret

;***************************************************************
; Plota um pixel preto na tela
plota_pixel2:
	push ax
	push bx
	push dx
	mov byte[cor],preto   
	mov bx,[coluna_atual]
	add bx,13 ;x
	push bx       
	mov bx,[linha_atual]
	add bx,389 ;y
	push bx       
	call plot_xy
	pop dx
	pop bx
	pop ax
	ret

;***************************************************************
; Função usada para pintar a direita de preto
limpa_imagem_d:
	push cx
	push ax
	push dx
	push bx
	mov word[linha_atual],0
	mov word[coluna_atual],0
	mov cx,300
	linhas3:
	push cx
	mov cx, 300

colunas3:
	call plota_pixel3
	inc word[coluna_atual]
	loop colunas3
	dec word[linha_atual]
	mov word[coluna_atual],0
	pop cx
	loop linhas3
	pop   bx
	pop   dx
	pop   ax    
	pop   cx
	ret

;***************************************************************
; Função que pinta um pixel preta na tela
plota_pixel3: 
	push ax
	push bx
	push dx
	mov byte[cor],preto   
	mov bx,[coluna_atual]
	add bx,333 ;x
	push bx       
	mov bx,[linha_atual]
	add bx,389 ;y
	push bx       
	call plot_xy
	pop dx
	pop bx
	pop ax
	ret

;***************************************************************
; Função que cria a interface do programa
criar_interface:     
	call criar_splits
	call text_abrir
	call text_sair
	call text_passa_baixa
	call text_passa_alta
	call text_texto_gradiente
	call text_identificacao
	ret

; Função para desenho das divisórias :
; faz as divisórias da interface a partir da função line
criar_splits:
	push ax       
	push bx       
	push cx       
	push dx       
	push si       
	push di   
		
	; Borda Superior
	mov ax,0                        
	push ax
	mov ax,479
	push ax
	mov ax,639
	push ax
	mov ax,479
	push ax
	call line

	; Borda Esquerda
	mov ax,0              
	push ax
	mov ax,0
	push ax
	mov ax,0
	push ax
	mov ax,479
	push ax
	call line

	; Borda Direita 
	mov ax,639             
	push ax
	mov ax,0
	push ax
	mov ax,639
	push ax
	mov ax,479
	push ax
	call line
		
	; Borda Inferior
	mov ax,0             
	push ax
	mov ax,0
	push ax
	mov ax,639
	push ax
	mov ax,0
	push ax
	call line
			
	; Divis�ria Vertical
	mov ax, 320                      
	push ax
	mov ax,90
	push ax
	mov ax, 320
	push ax
	mov ax,390
	push ax
	call line
		
	; Divis�ria Horizontal Inferior         
	mov ax, 0                      
	push ax
	mov ax,89
	push ax
	mov ax, 639
	push ax
	mov ax,89
	push ax
	call line
		
	; Divis�ria Horizontal Superior         
	mov ax, 0                      
	push ax
	mov ax,390
	push ax
	mov ax, 640
	push ax
	mov ax,390
	push ax
	call line
		
	; Primeira mini-divis�ria vertical
	mov ax, 80                      
	push ax
	mov ax,480
	push ax
	mov ax, 80
	push ax
	mov ax,390
	push ax
	call line
		
	; Segunda mini-divis�ria vertical   
	mov ax, 160                
	push ax
	mov ax,480
	push ax
	mov ax, 160
	push ax
	mov ax,390
	push ax
	call line

	; Terceira mini-divis�ria vertical    
	mov ax, 320                
	push ax
	mov ax,480
	push ax
	mov ax, 320
	push ax
	mov ax,390
	push ax
	call line
		
	; Quarta mini-divis�ria vertical    
	mov ax, 480                
	push ax
	mov ax,480
	push ax
	mov ax, 480
	push ax
	mov ax,390
	push ax
	call line

	; Quarta mini-divis�ria vertical    
	mov ax, 480                
	push ax
	mov ax,480
	push ax
	mov ax, 480
	push ax
	mov ax,390
	push ax
	call line

	; Divis�ria para identifica��o - vertical
	mov ax, 20                
	push ax
	mov ax,20
	push ax
	mov ax, 20
	push ax
	mov ax,70
	push ax
	call line

	; Divis�ria para identifica��o - vertical
	mov ax, 620                
	push ax
	mov ax,20
	push ax
	mov ax, 620
	push ax
	mov ax,70
	push ax
	call line

	; Divis�ria para identifica��o - horizontal
	mov ax, 20                
	push ax
	mov ax,70
	push ax
	mov ax, 620
	push ax
	mov ax,70
	push ax
	call line

	; Divis�ria para identifica��o - horizontal
	mov ax, 20                
	push ax
	mov ax,20
	push ax
	mov ax, 620
	push ax
	mov ax,20
	push ax
	call line
		
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax

	ret  

;***************************************************************
;Funções para escrita das mensagens na tela
;Utiliza as funções cursor e caracter
text_abrir:
	push ax
	push bx
	push cx
	push dx
	mov cx,5      ;número de caracteres
	mov bx,0
	mov dh,2      
	mov dl,2      

loop_abrir:
	call cursor
	mov al,[bx+texto_abrir]
	call  caracter
	inc bx      
	inc dl      ;avanca a coluna
	loop loop_abrir
	pop dx 
	pop cx
	pop bx
	pop ax
	ret

text_sair:
	push ax
	push bx
	push cx
	push dx
	mov cx,4      
	mov bx,0
	mov dh,2            
	mov dl,12     

loop_sair:
	call cursor
	mov al,[bx+texto_sair]
	call caracter
	inc bx      
	inc dl      ;avanca a coluna

	loop loop_sair
	pop dx 
	pop cx
	pop bx
	pop ax
	ret
	
text_passa_baixa:
	push ax
	push bx
	push cx
	push dx
	mov cx,11     
	mov bx,0
	mov dh,2           
	mov dl,24     


loop_passa_baixa:
	call cursor
	mov al,[bx+texto_passa_baixa]
	call caracter
	inc bx              
	inc dl              ;avanca a coluna
	loop loop_passa_baixa
	pop dx 
	pop cx
	pop bx
	pop ax
	ret ; ret é utilizado para retornar ao ponto de chamada da função
	
text_passa_alta:
	push ax
	push bx
	push cx
	push dx
	mov cx,10     
	mov bx,0
	mov dh,2           
	mov dl,45     

loop_passa_alta:
	call cursor
	mov al,[bx+texto_passa_alta]
	call caracter
	inc bx              
	inc dl              ;avanca a coluna
	loop loop_passa_alta
	pop dx 
	pop cx
	pop bx
	pop ax
	ret 
	
text_texto_gradiente:
	push ax
	push bx
	push cx
	push dx
	mov cx,9
	mov bx,0
	mov dh,2           
	mov dl,65     

loop_texto_gradiente:
	call cursor
	mov al,[bx+texto_gradiente]
	call caracter
	inc bx              
	inc dl              ;avança a coluna
	loop loop_texto_gradiente
	pop dx 
	pop cx
	pop bx
	pop ax
	ret 
	
text_identificacao:
	push ax
	push bx
	push cx
	push dx
	mov cx,47     
	mov bx,0
	mov dh,27           
	mov dl,14

loop_identificacao:
	call cursor
	mov al,[bx+texto_rodape]
	call caracter
	inc bx              
	inc dl  ; avanca a coluna para o próximo caracter
	loop loop_identificacao
	pop dx 
	pop cx
	pop bx
	pop ax
	ret 

;***************************************************************
;
; FILTROS
;
;***************************************************************  

; Filtro passa-baixa
filtro_passa_baixa:
	push ax
	push bx
	push cx
	push dx
	cmp byte[aberto],0
	jne continua_f_pb
	pop dx
	pop cx
	pop bx
	pop ax
	ret
	
continua_f_pb:
	call limpa_imagem_d
	call leitura_linhas_inicial
	mov word[coluna_atual],0
	mov word[linha_atual],0
	mov bx,0
	mov cx,300


pinta_primeira_preto:
	mov byte[current],preto
	call plota_pixel_filtros
	inc word[coluna_atual]
	inc bx
	loop pinta_primeira_preto ; Pinta a primeira linha de preto para evitar que o filtro não funcione
	dec word[linha_atual]
	mov word[coluna_atual],0
	mov bx,0
	mov cx,300

faz_primeira_linha:
	xor ax,ax
	xor dx,dx
	mov al,byte[linha_meio + bx]
	mov dl,byte[linha_meio + bx + 1]
	add ax,dx
	mov dl,byte[linha_meio + bx - 1]
	add ax,dx
	mov dl,byte[linha_superior + bx]
	add ax,dx
	mov dl,byte[linha_superior + bx + 1]
	add ax,dx
	mov dl,byte[linha_superior + bx - 1]
	add ax,dx
	mov dl,byte[linha_inferior + bx]
	add ax,dx
	mov dl,byte[linha_inferior + bx + 1]
	add ax,dx
	mov dl,byte[linha_inferior + bx - 1]
	add ax,dx
	mov dl,9
	div dl
	mov [current],al
	call plota_pixel_filtros
	inc word[coluna_atual]
	inc bx
	loop faz_primeira_linha
	dec word[linha_atual]
	mov word[coluna_atual],0
	
	mov cx,298


faz_outras_linhas:
	push cx
	call leitura_linhas_continuada
	mov bx,0

faz_colunas:
	xor ax,ax
	xor dx,dx
	mov al,byte[linha_meio + bx]
	mov dl,byte[linha_meio + bx + 1]
	add ax,dx
	mov dl,byte[linha_meio + bx - 1]
	add ax,dx
	mov dl,byte[linha_superior + bx]
	add ax,dx
	mov dl,byte[linha_superior + bx + 1]
	add ax,dx
	mov dl,byte[linha_superior + bx - 1]
	add ax,dx
	mov dl,byte[linha_inferior + bx]
	add ax,dx
	mov dl,byte[linha_inferior + bx + 1]
	add ax,dx
	mov dl,byte[linha_inferior + bx - 1]
	add ax,dx
	mov dl,9
	div dl
	mov [current],al
	call plota_pixel_filtros
	inc word[coluna_atual]
	inc bx
	cmp bx,300
	jne faz_colunas
	dec word[linha_atual]
	mov word[coluna_atual],0
	pop cx
	loop faz_outras_linhas

	mov bx,[file_handle]
	mov ah,3eh
	mov al,00h
	int 21h

	pop dx
	pop cx
	pop bx
	pop ax
	ret

;***************************************************************
; Filtro passa-alta
filtro_passa_alta:
	push ax
	push bx
	push cx
	push dx
	cmp byte[aberto],0
	jne continua_f_pa
	pop dx
	pop cx
	pop bx
	pop ax
	ret
continua_f_pa:
	call limpa_imagem_d

	call leitura_linhas_inicial
	mov word[coluna_atual],0
	mov word[linha_atual],0
	mov bx,0
	mov cx,300

pinta_primeira_preto2:
	mov byte[current],preto
	call plota_pixel_filtros
	inc word[coluna_atual]
	inc bx
	; Pinta a primeira linha de preto para evitar que o filtro não funcione
	loop pinta_primeira_preto2

	dec word[linha_atual]
	mov word[coluna_atual],0
	mov bx,0
	mov cx,300

faz_primeira_linha2:
	xor ax,ax
	xor dx,dx
	mov al,[linha_meio + bx]
	mov dh,9
	mul dh
	xor dh,dh
	mov dl,[linha_meio + bx + 1]
	sub ax,dx
	mov dl,[linha_meio + bx - 1]
	sub ax,dx
	mov dl,[linha_superior + bx]
	sub ax,dx
	mov dl,[linha_superior + bx + 1]
	sub ax,dx
	mov dl,[linha_superior + bx - 1]
	sub ax,dx
	mov dl,[linha_inferior + bx]
	sub ax,dx
	mov dl,[linha_inferior + bx + 1]
	sub ax,dx
	mov dl,[linha_inferior + bx - 1]
	sub ax,dx
	mov [auxiliar],ax

	or  ax, 0 ;seta flags         
	jns nao_negativo

		mov word[auxiliar],0
	nao_negativo:
	mov ax,[auxiliar]

	cmp ax,255
	jb move
	mov ax,255
	move:
	mov [current],al
	call plota_pixel_filtros
	inc word[coluna_atual]
	inc bx
	loop faz_primeira_linha2
		
	dec word[linha_atual]
	mov word[coluna_atual],0
		
	mov cx,298

faz_outras_linhas2:
	push cx
		; L� os pr�ximos conjuntos de 3 linhas
	call leitura_linhas_continuada
	mov bx,0
faz_colunas2:
	xor ax,ax
	xor dx,dx
	mov al,[linha_meio + bx]
	mov dh,9
	mul dh
	xor dh,dh
	mov dl,[linha_meio + bx + 1]
	sub ax,dx
	mov dl,[linha_meio + bx - 1]
	sub ax,dx
	mov dl,[linha_superior + bx]
	sub ax,dx
	mov dl,[linha_superior + bx + 1]
	sub ax,dx
	mov dl,[linha_superior + bx - 1]
	sub ax,dx
	mov dl,[linha_inferior + bx]
	sub ax,dx
	mov dl,[linha_inferior + bx + 1]
	sub ax,dx
	mov dl,[linha_inferior + bx - 1]
	sub ax,dx
	mov [auxiliar],ax
	or  ax, 0       
	jns nao_negativo2
	; Se sim, muda para o valor mais pr�ximo da
	; escala de cinza, no caso 0
	mov word[auxiliar],0
	nao_negativo2:
	mov ax,[auxiliar]
	; Se n�o � negativo, verifica se o valor deu acima de 255,
	; valor m�ximo da escala de cinza. Se sim, muda para o
	; valor mais pr�ximo, no caso, 255.
	cmp ax,255
	jb move2
	mov ax,255
	move2:
	mov [current],al
	call plota_pixel_filtros
	inc word[coluna_atual]
	inc bx
	cmp bx,300
	jne faz_colunas2
	dec word[linha_atual]
	mov word[coluna_atual],0
	pop cx
	loop faz_outras_linhas2

	; Fecho o arquivo ap�s realiza��o do filtro
	mov bx,[file_handle]
	mov ah,3eh
	mov al,00h
	int 21h	

	pop dx
	pop cx
	pop bx
	pop ax
	ret

;***************************************************************
; Filtro texto_gradiente
filtro_texto_gradiente:
	push ax
	push bx
	push cx
	push dx
	cmp byte[aberto],0
	; Se o arquivo ainda n�o tiver sido aberto, n�o faz filtro
	jne continua_f_gra
	pop dx
	pop cx
	pop bx
	pop ax
	ret
	
continua_f_gra:
call limpa_imagem_d
; L� 3 primeiras linhas do arquivo
call leitura_linhas_inicial
mov word[coluna_atual],0
mov word[linha_atual],0
mov bx,0
mov cx,300
	

pinta_primeira_preto3:
	mov byte[current],preto
	call plota_pixel_filtros
	inc word[coluna_atual]
	inc bx
loop pinta_primeira_preto3

dec word[linha_atual]
mov word[coluna_atual],0
mov bx,0
mov cx,300

faz_primeira_linha3:
	;Gx
	xor ax,ax
	xor dx,dx
	mov al,[linha_superior + bx]
	mov dh,2
	imul dh
	xor dh,dh
	sub dx,ax
	mov ax,dx
	xor dh,dh
	mov dl,[linha_superior + bx + 1]
	sub ax,dx 
	mov dl,[linha_superior + bx - 1]
	sub ax,dx
	mov dx,ax
	mov al,[linha_inferior + bx]
	xor ah,ah
	push bx
	mov bh,2
	mul bh
	pop bx
	add ax,dx
	mov dl,[linha_inferior + bx + 1]
	xor dh,dh
	add ax,dx
	mov dl,[linha_inferior + bx - 1]
	add ax,dx
	mov [auxiliar],ax
	;Verifica se Gx foi negativo
	or ax,0
	jns faz_gy
	;Se sim, pega o m�dulo de Gx e faz Gy
	neg word[auxiliar]
	;Se n�o, faz Gy direto
	faz_gy:
	; Gy
	xor ax,ax
	xor dx,dx
	mov dl,[linha_superior + bx + 1]
	add ax,dx 
	mov dl,[linha_superior + bx - 1]
	sub ax,dx
	mov dl,[linha_inferior + bx + 1]
	add ax,dx 
	mov dl,[linha_superior + bx - 1]
	sub ax,dx
	mov dx,ax
	mov al,[linha_meio + bx + 1]
	xor ah,ah
	push bx
	mov bh,2
	mul bh
	pop bx
	add ax,dx 
	mov dx,ax
	mov al,[linha_meio + bx - 1]
	xor ah,ah
	push bx
	mov bh,2
	mul bh
	pop bx
	sub dx,ax
	mov ax,dx
	mov dx,ax
	; Verifica se Gy foi negativo
	or ax,0
	jns soma_gxgy
	;Se sim, pega o m�dulo
	neg dx
	;Se n�o, soma Gx e Gy
	soma_gxgy:
	add dx,[auxiliar]
	;Verifica se valor excede  limite escala (255)
	cmp dx,255
	jb move3
	mov dx,255
	move3:
	mov [current],dl
	call plota_pixel_filtros
	inc word[coluna_atual]
	inc bx
	dec cx
	cmp cx,0
je continu
jmp faz_primeira_linha3
	
continu:
dec word[linha_atual]
mov word[coluna_atual],0
	
mov cx,298
faz_outras_linhas3:
	push cx
	call leitura_linhas_continuada
	mov bx,0
	faz_colunas3:
		xor ax,ax
		xor dx,dx
		mov al,[linha_superior + bx]
		mov dh,2
		imul dh
		xor dh,dh
		sub dx,ax
		mov ax,dx
		xor dh,dh
		mov dl,[linha_superior + bx + 1]
		sub ax,dx 
		mov dl,[linha_superior + bx - 1]
		sub ax,dx
		mov dx,ax
		mov al,[linha_inferior + bx]
		xor ah,ah
		push bx
		mov bh,2
		mul bh
		pop bx
		add ax,dx
		mov dl,[linha_inferior + bx + 1]
		xor dh,dh
		add ax,dx
		mov dl,[linha_inferior + bx - 1]
		add ax,dx
		mov [auxiliar],ax
		or ax,0
		jns faz_gy2
		;Se Gx for negativo, pega o m�dulo
		neg word[auxiliar]
		faz_gy2:
		; Gy
		xor ax,ax
		xor dx,dx
		mov dl,[linha_superior + bx + 1]
		add ax,dx 
		mov dl,[linha_superior + bx - 1]
		sub ax,dx
		mov dl,[linha_inferior + bx + 1]
		add ax,dx 
		mov dl,[linha_superior + bx - 1]
		sub ax,dx
		mov dx,ax
		mov al,[linha_meio + bx + 1]
		xor ah,ah
		push bx
		mov bh,2
		mul bh
		pop bx
		add ax,dx 
		mov dx,ax
		mov al,[linha_meio + bx - 1]
		xor ah,ah
		push bx
		mov bh,2
		mul bh
		pop bx
		sub dx,ax
		mov ax,dx
		mov dx,ax
		or ax,0
		jns soma_gxgy2
		; Se Gy for negativo, pega o m�dulo
		neg dx
		soma_gxgy2:
		add dx,[auxiliar]
		; Verifica se o resultado da mascara ultrapassa limite superior (255)
		cmp dx,255
		jb move4
		mov dx,255
		move4:
		mov [current],dl
		call plota_pixel_filtros
		inc word[coluna_atual]
		inc bx
		cmp bx,300
	je fim_colunas
	jmp faz_colunas3
	fim_colunas:
	dec word[linha_atual]
	mov word[coluna_atual],0
	pop cx
	dec cx
	cmp cx,0
je sai_3
jmp faz_outras_linhas3

sai_3:
;Fecha arquivo ap�s aplicar filtro
mov bx,[file_handle]
mov ah,3eh
mov al,00h
int 21h

pop dx
pop cx
pop bx
pop ax
ret  
	
;***************************************************************
;
; FUN��ES AUXILIARES - FILTROS
;
;***************************************************************
;L� as tr�s primeiras linhas do arquivo para execu��o de um filtro   
leitura_linhas_inicial:
push ax
push bx
push cx
push dx

	;mov bx,[file_handle]
	;mov ah,3eh
	;mov al,00h
	;int 21h

mov ah,3dh        
mov al,00h
mov dx,file_name
int 21h
mov [file_handle],ax  
	
mov bx, [file_handle]
mov dx, buffer      ; Caracter lido do arquivo em dx
mov cx,1          ; Ler� um byte por vez
mov ah,3Fh          ; Interrup��o respons�vel por leitura do arquivo
int 21h                 
mov word[num_lidos],0
	
linha_superiora:
	mov bx,[file_handle]
	mov dx, buffer
	mov cx,1      ; quantidade de bytes a serem lidos: 1 char por vez
	mov ah,3Fh      ; 3Fh - l� o arquivo
	int 21h       
	;cmp ax,cx
	;jne saie
	mov al, [buffer]
	;Caso o byte lido seja um espa�o, um novo pixel dever� ser lido
	mov [ascii],al
	cmp al,20h
	je proximo_numero_superior
	call asciiparadecimal
jmp linha_superiora
	
proximo_numero_superior:
	call junta_digitos
	mov ah,[decimal]
	mov bx,[num_lidos]
	mov [linha_superior + bx],ah
	inc word[num_lidos]
	cmp word[num_lidos],300
jne linha_superiora

mov word[num_lidos],0
linha_meioa:
	mov bx,[file_handle]
	mov dx, buffer
	mov cx,1      ; quantidade de bytes a serem lidos: 1 char por vez
	mov ah,3Fh      ; 3Fh - l� o arquivo
	int 21h       
	mov al, [buffer]
	mov [ascii],al
	;Caso o byte lido seja um espa�o, um novo pixel dever� ser lido
	cmp al,20h
	je proximo_numero_meio
	call asciiparadecimal
jmp linha_meioa
	
proximo_numero_meio:
	call junta_digitos
	mov ah,[decimal]
	mov bx,[num_lidos]
	mov [linha_meio + bx],ah
	inc word[num_lidos]
	cmp word[num_lidos],300
jne linha_meioa
	
mov word[num_lidos],0
linha_inferiora:
	mov bx,[file_handle]
	mov dx, buffer
	mov cx,1      ; quantidade de bytes a serem lidos: 1 char por vez
	mov ah,3Fh      ; 3Fh - l� o arquivo
	int 21h       
	mov al, [buffer]
	mov [ascii],al
	;Caso o byte lido seja um espa�o, um novo pixel dever� ser lido
	cmp al,20h
	je proximo_numero_inferior
	call asciiparadecimal
jmp linha_inferiora
	
proximo_numero_inferior:
	call junta_digitos
	mov ah,[decimal]
	mov bx,[num_lidos]
	mov [linha_inferior + bx],ah
	inc word[num_lidos]
	cmp word[num_lidos],300
jne linha_inferiora
	
saie:
pop dx
pop cx
pop bx
pop ax
ret 

;***************************************************************
;L� as pr�ximas tr�s linhas do arquivo para execu��o de um filtro

leitura_linhas_continuada:
push ax
push bx
push cx
push dx
mov bx,0
mov cx,300

; No novo grupo de tr�s linhas,
; a linha superior passa a ser a do meio antiga,
; e a do meio passa a ser a inferior antiga.
troca_vetor:
	mov al,[linha_meio + bx]
	mov [linha_superior + bx],al
	mov al,[linha_inferior + bx]
	mov [linha_meio + bx], al
	inc bx
loop troca_vetor
	
mov word[num_lidos],0
;Apenas a nova linha inferior precisa ser lida.
linha_inferior_2:
	mov bx,[file_handle]
	mov dx, buffer
	mov cx,1      ; quantidade de bytes a serem lidos: 1 char por vez
	mov ah,3Fh      ; 3Fh - l� o arquivo
	int 21h
	cmp ax,cx
	jne saie2       
	mov al, [buffer]
	mov [ascii],al
	;Caso o byte lido seja um espa�o, um novo pixel dever� ser lido
	cmp al,20h
	je proximo_numero_inferior2
	call asciiparadecimal
jmp linha_inferior_2
	
proximo_numero_inferior2:
	call junta_digitos
	mov ah,[decimal]
	mov bx,[num_lidos]
	mov [linha_inferior + bx],ah
	inc word[num_lidos]
	cmp word[num_lidos], 300
jne linha_inferior_2
	
saie2:
pop dx
pop cx
pop bx
pop ax
ret

; Função que plota um ponto
plot_xy:
	push bp
	mov bp,sp
	pushf
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	mov ah,0ch
	mov al,[cor]
	mov bh,0
	mov dx,479
	sub dx,[bp+4]
	mov cx,[bp+6]
	int 10h
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	popf
	pop bp
	ret 4

;***************************************************************  
	; Fun��o que desenha linhas
line:
	push bp
	mov bp,sp
	pushf                        ;coloca os flags na pilha
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	mov ax,[bp+10]   ; resgata os valores das coordenadas
	mov bx,[bp+8]    ; resgata os valores das coordenadas
	mov cx,[bp+6]    ; resgata os valores das coordenadas
	mov dx,[bp+4]    ; resgata os valores das coordenadas
	cmp ax,cx
	je line2
	jb line1
	xchg ax,cx
	xchg bx,dx
	jmp line1
	
line2:    ; deltax=0
	cmp bx,dx  ;subtrai dx de bx
	jb line3
	xchg bx,dx        ;troca os valores de bx e dx entre eles
		
	line3:  ; dx > bx
	push ax
	push bx
	call plot_xy
	cmp bx,dx
	jne line31
	jmp fim_line
		
	line31: 
	inc bx
	jmp line3
	;deltax <>0
	
line1:
; comparar módulos de deltax e deltay sabendo que cx>ax
; cx > ax
	push cx
	sub cx,ax
	mov [deltax],cx
	pop cx
	push dx
	sub dx,bx
	ja line32
	neg dx

line32:   
	mov [deltay],dx
	pop dx
	push ax
	mov ax,[deltax]
	cmp ax,[deltay]
	pop ax
	jb line5

	; cx > ax e deltax>deltay
	push cx
	sub cx,ax
	mov [deltax],cx
	pop cx
	push dx
	sub dx,bx
	mov [deltay],dx
	pop dx
	mov si,ax
	
line4:
	push ax
	push dx
	push si
	sub si,ax ;(x-x1)
	mov ax,[deltay]
	imul si
	mov si,[deltax]   ;arredondar
	shr si,1
	; se numerador (DX)>0 soma se <0 subtrai
	cmp dx,0
	jl ar1
	add ax,si
	adc dx,0
	jmp arc1

ar1:
	sub ax,si
	sbb dx,0

arc1:
	idiv word [deltax]
	add ax,bx
	pop si
	push si
	push ax
	call plot_xy
	pop dx
	pop ax
	cmp si,cx
	je  fim_line
	inc si
	jmp line4

line5:    
	cmp bx,dx
	jb  line7
	xchg ax,cx
	xchg bx,dx

line7:
	push cx
	sub cx,ax
	mov [deltax],cx
	pop cx
	push dx
	sub dx,bx
	mov [deltay],dx
	pop dx
	mov si,bx
	
line6:
	push dx
	push si
	push ax
	sub si,bx ;(y-y1)
	mov ax,[deltax]
	imul si
	mov si,[deltay]   ;arredondar
	shr si,1
	; se numerador (DX)>0 soma se <0 subtrai
	cmp dx,0
	jl ar2
	add ax,si
	adc dx,0
	jmp arc2
	
ar2:    
	sub ax,si
	sbb dx,0

arc2:
	idiv word [deltay]
	mov di,ax
	pop ax
	add di,ax
	pop si
	push di
	push si
	call plot_xy
	pop dx
	cmp si,dx
	je fim_line
	inc si
	jmp line6
		
fim_line:
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	popf
	pop bp
	ret 8 
	
;***************************************************************  
; Fun��o Cursor
; dh = linha (0-29) e  dl=coluna  (0-79)
cursor:
	pushf
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	push bp
	mov ah,2
	mov bh,0
	int 10h
	pop bp
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	popf
	ret
	
;***************************************************************
; Fun��o Caracter
; al= caracter a ser escrito
; cor definida na variavel cor
caracter:
	pushf
	push ax
	push bx
	push cx
	push dx
	push si
	push di
	push bp
	mov ah,9
	mov bh,0
	mov cx,1
	mov bl,[cor]
	int 10h
	pop bp
	pop di
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	popf
	ret 
	
; Sair do programa
sair:
mov ah,0                ; set video mode
mov al,[modo_anterior]    ; modo anterior
int 10h
mov ax,4c00h
int 21h

;***************************************************************
;
; SEGMENTO DE DADOS
;
;***************************************************************  
	  
segment data

; Constantes de cores utilizadas
cor           db    branco_intenso
	

; I R G B COR
; 0 0 0 0 preto
; 0 0 0 1 azul
; 0 0 1 0 verde
; 0 0 1 1 cyan
; 0 1 0 0 vermelho
; 0 1 0 1 magenta
; 0 1 1 0 marrom
; 0 1 1 1 branco
; 1 0 0 0 cinza
; 1 0 0 1 azul claro
; 1 0 1 0 verde claro
; 1 0 1 1 cyan claro
; 1 1 0 0 rosa
; 1 1 0 1 magenta claro
; 1 1 1 0 amarelo
; 1 1 1 1 branco intenso

preto			equ   0
azul			equ   1
verde			equ   2
cyan      		equ   3
vermelho    	equ   4
magenta     	equ   5
marrom      	equ   6
branco      	equ   7
cinza     		equ   8
azul_claro    	equ   9
verde_claro   	equ   10
cyan_claro    	equ   11
rosa      		equ   12
magenta_claro 	equ   13
amarelo     	equ   14
branco_intenso  equ   15


modo_anterior 	db    0
deltax      	dw    0
deltay      	dw    0
	

; textos do Menu
texto_abrir			db    	'ABRIR'
texto_sair			db      'SAIR'
texto_passa_baixa   db      'PASSA-BAIXA'
texto_passa_alta    db      'PASSA-ALTA'
texto_gradiente     db      'GRADIENTE'
texto_rodape        db      'Sistemas Embarcados I - 2025/1 - Joao Gabriel S. Custodio'
	
; Variáveis para leitura e abertura de arquivo
file_name		db		'imagem.txt$',00h
file_handle   	dw      0
buffer        	db    	0
aberto        	db    	0
dezena       	db    	0
unidade       	db    	0
centena       	db    	0
linha_atual   	dw    	0
coluna_atual  	dw    	0
decimal      	db    	0
linha_superior  resb  	300
linha_meio    	resb  	300
linha_inferior  resb  	300
num_lidos   	dw   	0
bytes_lidos   	dw 		0
current     	db		0
auxiliar		dw		0
ascii			db		0

segment stack stack
resb    512
stacktop:
