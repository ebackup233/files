<?php
#get_header();

/*
 ## Você precisa primeiro baixar o PHPMailer
 wget https://github.com/PHPMailer/PHPMailer/archive/refs/tags/v6.5.0.tar.gz
 tar -xf v6.5.0.tar.gz
 mv PHPMailer-6.5.0/src PHPMailer
 rm -rf PHPMailer-6.5.0 v6.5.0.tar.gz
 ## Para enviar o teste
 php -q send_mail.php
 */

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

require 'PHPMailer/Exception.php';
require 'PHPMailer/PHPMailer.php';
require 'PHPMailer/SMTP.php';

$mail = new PHPMailer();
$mail->IsSMTP();
## Voce precisa ajustar as linhas abaixo para seu Servidor
$mail->Host = "mail.seudominio.com.br";
$mail->Username = "EMAIL@seudominio.com.br";
$mail->Password = "SENHADOEMAIL";
$mail->From = "EMAIL@seudominio.com.br";
$mail->AddAddress('jniltinho@gmail.com');
## Para enviar para mais pessoas ajuste aqui e descomente a linha
#$mail->addReplyTo('nilton@linuxpro.com.br');
#$mail->addCC('linuxpro@linuxpro.com.br');
$mail->FromName = "Servidor de E-mail com Postfix";
$mail->SMTPAuth   = true;
$mail->SMTPSecure = "tls";
$mail->Port       = 587;
$mail->IsHTML(true);
$mail->Subject = "Teste de E-mail Nilton";
$mail->Body    = "Mail Test - Servidor de E-Mail do Curso Postfix";
$mail->IsHTML(true);
if(!$mail->Send())
  {
  echo "Erro ao Enviar o Email\n";
  } else {
  echo "Email enviado com sucesso\n";
}
?>
