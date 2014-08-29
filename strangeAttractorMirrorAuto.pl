use strict;
use GD::Simple;

if (@ARGV != 3) {
  print "Usage: perl strangeAttractorExComp.pl [tryNum] [evalTh] [fileId]\n";
  exit;
}
my @colors = ();
my $img;
my $nameParam;

my $tryNum = $ARGV[0];
my $evalTh = $ARGV[1];
my $fileID = $ARGV[2];

my $margin = 5;

sub minmax {
  my @ret = ();
  my ($x, $y, $minx, $miny, $maxx,$maxy) = @_;
  @ret = (($x < $minx) ? $x : $minx, ($y < $miny) ? $y : $miny, ($x > $maxx) ? $x : $maxx, ($y > $maxy) ? $y : $maxy);

  return @ret;
}
sub transform {
 my @ret = ();
 my ($x, $y, $minx, $miny, $maxx, $maxy, $w, $h) = @_;
 $ret[0] = int (($x-$minx)*$w/($maxx-$minx));
 $ret[1] = int (($y-$miny)*$h/($maxy-$miny));
 
 return @ret;
}
sub attractorEq1
{
  my ($x, $y, @a) = @_;
  my @ret = ();
  $ret[0] = $a[1] + $x*($a[2] + $a[3]*$x + $a[ 4]*$y) + $y*($a[ 5] + $a[ 6]*$y);
  $ret[1] = $a[7] + $x*($a[8] + $a[9]*$x + $a[10]*$y) + $y*($a[11] + $a[12]*$y);
  return @ret;
}
sub evaluateAttractor {
  my $ret = 0;
  my @a = @_;

  my $minx = $a[13];
  my $miny = $a[14];
  my $maxx = $a[15];
  my $maxy = $a[16];

  my $divX = 40;
  my $divY = 40;
  my $sparseTh = $evalTh;
  my @cell = ();

  my $x = 0.5;
  my $y = 0.5;

  my $i;
  my $maxTry = 10000;
  for ($i=0; $i<$maxTry; $i++) {
    my ($x1, $y1) = attractorEq1($x, $y, @a);
    my ($xt, $yt) = transform($x1, $y1, $minx, $miny, $maxx, $maxy, $divX, $divY);
    my $index = (int($xt)%20)*20+int($yt)%20;
    $cell[$index] = $cell[$index] + 1;
    $x = $x1;
    $y = $y1;
  }
  my $sum = 0;
  for ($i=0; $i<$divX*$divY; $i++) {
    if ($cell[$i] > 0) {
      $sum++;
    }
  }
  if ($sum > $sparseTh) {
    $ret = $sum;
  }
  return $ret;
}
sub findStrangeAttractor {
  my @a = ();
  my $i = 0;
  my $j = 0;
  my $maxLoop = 10000;
  my $maxTry = 10000;
  my $th = 1000000;
  my $maxOut = $tryNum;

  my $id = 0;


  srand time;

  for ($i=0; $i<$maxLoop; $i++) {
    my $x = 0.5;
    my $y = 0.5;
    my $minx = $x;
    my $miny = $y;
    my $maxx = $x;
    my $maxy = $y;
  
    $a[0] = $i;
    for ($j=1; $j<=12; $j++) {
      $a[$j] = 0.1*(rand(25)-12);
    }
    for ($j=0; $j<$maxTry; $j++) {
      my ($x1, $y1) = attractorEq1($x, $y, @a);
      ($minx, $miny, $maxx, $maxy) = minmax($x1, $y1, $minx, $miny, $maxx, $maxy);
      if ((abs($x1) + abs($y1)) > $th) {
        last;
      }
      $x = $x1;
      $y = $y1;
    }
    if ($j >= $maxTry) {
      #foud a strange attractor
      $a[13] = $minx;
      $a[14] = $miny;
      $a[15] = $maxx;
      $a[16] = $maxy;
      $a[17] = int(rand(6)); #$id;
      my $sparse = evaluateAttractor(@a);
      if ($sparse != 0) { 
        $a[18] = $sparse;
        open( OUT_p, ">> $nameParam") or die( "Cannot open file: $nameParam" );
        print OUT_p "@a\n";
        close(OUT_p);
        outputStrangeAttractor(@a);
        $id++;
        if ($id >= $maxOut) {
          last;
        }
      }
    }
  }
  #output the image
  my $name = "strangeAttractorComp" . $fileID . ".png";
  open( OUT, "> $name") or die( "Cannot open file: graph.jpg" );
  binmode OUT;
  print OUT $img->png;
}
sub outputStrangeAttractor {
  my @a = @_;

  my $minx = $a[13];
  my $miny = $a[14];
  my $maxx = $a[15];
  my $maxy = $a[16];
  my $id = $a[17];
  my $imgW = 2048-2*$margin;
  my $imgH = 2048-2*$margin;
  
  my $j = 0;
  my $x = 0.5;
  my $y = 0.5;
  my $maxTry = 100000;
  for ($j=0; $j<$maxTry; $j++) {
    my ($x1, $y1) = attractorEq1($x, $y, @a);
    my ($xt, $yt) = transform($x1, $y1, $minx, $miny, $maxx, $maxy, $imgW/2, $imgH/2);
    $img->setPixel($margin+$xt,       $margin+      $yt, $colors[$id%25]);
    $img->setPixel($margin+$imgW-$xt, $margin+      $yt, $colors[$id%25]); #horizontal mirror
    $img->setPixel($margin+$xt,       $margin+$imgH-$yt, $colors[$id%25]); #vertical mirror
    $img->setPixel($margin+$imgW-$xt, $margin+$imgH-$yt, $colors[$id%25]); #diagonal mirror
    $x = $x1;
    $y = $y1;
  }
}
sub createImage {
  my ($imgW, $imgH) = @_;
  my $imgWOut = $imgW;
  my $imgHOut = $imgH;
  
  # create a new image
  $img = GD::Simple->new($imgWOut,$imgHOut);
  
  # draw a red rectangle with blue borders
  $img->bgcolor('black');
  $img->fgcolor('green');
  
  my $black = $img->colorAllocate(0,0,0);
  my $green = $img->colorAllocate(0,255,0);
  
  $img->rectangle(0,0,$imgWOut,$imgHOut,$black);
  $img->fill(50,50,$black);
  
    
  my $i = 0;

  for ($i=0; $i<=4; $i++) {
    my $val = (($i+1)*64)%216;
    $colors[$i*6+0] = $img->colorAllocate($val,    0,    0); 
    $colors[$i*6+1] = $img->colorAllocate(   0, $val,    0); 
    $colors[$i*6+2] = $img->colorAllocate(   0,    0, $val); 
    $colors[$i*6+3] = $img->colorAllocate($val, $val,    0); 
    $colors[$i*6+4] = $img->colorAllocate($val,    0, $val); 
    $colors[$i*6+5] = $img->colorAllocate(   0, $val, $val); 
  }
  $img->transparent($black);
}
my $loop=0;
for ($loop=0; $loop<100; $loop++) {
  $nameParam = "t" . $fileID . ".txt";
  createImage(2048, 2048);
  findStrangeAttractor();
  $fileID++;
}
