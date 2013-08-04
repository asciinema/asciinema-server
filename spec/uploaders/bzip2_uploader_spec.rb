require 'spec_helper'

describe Bzip2Uploader do
  let(:uploader) { Bzip2Uploader.new(user, :photo) }
  let(:user) { User.new }

  describe '#decompressed' do
    context "when file wasn't stored" do
      it 'returns nil' do
        expect(uploader.decompressed).to be(nil)
      end
    end

    context "when file was stored" do
      before do
        uploader.store!(File.open('spec/fixtures/munch.bz2'))
      end

      it 'returns decompressed data as a string' do
        expect(uploader.decompressed).to eq(<<EOS)
Edvard Munch - The Scream
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXP
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXY?"""  .
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXY?""   ,;ciCCC
"?YXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXYYY??""   .,;iCCCCCCCCCC
.,.  `""""""???YYYYYYYYYYXXXXXXXYYYYY???"""""""   ..,;ciiCCCCCCCCCCC''`
```'`CCiiicccccccccc;;,,.    .,..,..,;cccciiiCCCCCCC????>''`````   .;ciCCC
Cic;,.   `''<<????CCCCCCCCCCCC?????''''''''`````'   ..,;;;ccciiiCCCCCCCCCC
CCCCCCCCCCCCcc;;;,,.       .,..,..,..,;;cciiiiCCCCCCCCCCCCCCCCCCCCC??>'`
``''?CCCCCCCCCC"'```''CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC??""''``   _.,;cciCC
ic;;,. ````'<?Ciiccc;,,.  ````'''`CCCCCC''''''''`' .,;cciiiCCCCCCCCCC?"'`
CCCCCCCCCiic;._  ```''"<?CCC;;;,,,.,..,...,;;;;;;C777???CC'''''``'  _,xiXX
.  ```'''`CCCCCCCiicc;,,,,,..        ```````'            .,,,xiiXXXXXXXXXX
XXXXXxXx,,,.   ```````````````````   .,..,..,.xiXiiXiiXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXxXxxXxXXXXXxxXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXY??"""
"""?YXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXYY???"""
=          """""???YYXXXXXXXXXXXXXXXXXXXXXXXXXXYYY???""                 ,;
 -;ccccc;;,.,..            """"""""""                          ,;ciCC'``'
;;, ```'???CCCCC  `''--;CCicc;;,      .,;;,,,.   ..      .,;ciCCCCCCCicc;-
C'```CCiiiiiCCCCtCiicc;,.  ```' . .,;;iCCCCC'' .,;;cccc-''`CCCCCCCCCCCCC;;
CCCCc;,,.,;CCCcc,,,,..'' .;CC'`'CCCCCCCCCC'' ``' .,;;;cc===`CC''````````'
.,...```' .C.,.`""""?CCCCC'`CCC''''``'  .,.,;ciCCCCCC..,;cciiCtttCCCCCCCtt
 ```'     `'`CCCCCCCCCCC' . `'       ```' .,. ```CCC''''`CCCCCCCCCCCCC?"''
..                           ``'                            ```'
$$$$$$$$$$$$ccc$$$$$$$$"?hccc=Jcc$$hccccccc$$$$$$$$$$$$$cccccc,,,,,ccc,,..
$$$??hcccci???CCCCCC$$L ,$$$$c $$hcccccJ???LcccccccccJCCC???????CCCC??????
$$F `?$$$$$$$$$$$$$$$$. ,$$"$$.?$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
$$,. ,$$$$$$$$$$$$$$$$. ,$$ $$h $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$??????????$$
$$$h $$$$$$$$$$$$$$$$$$ $$$ ?$h ?$$$$$$$$$$$$$$$$$$$$$$$???izc?????????i??
???" ?????$$$$$$$""""""  "" ?"" `"?"""$$$$$$$$??<Lr??cr?=""    .  .      .
,,,,,,,,,J$$$$$$$$,.,,,,,,,,..       ,$$$$$$P>JP"       .,;;,.!!;,.!!!!!!!
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$C3$$  -'  --''`!!!!'`'   ..  `!
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$Ci??c,,,.,..,.            `````
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$JJCCCC????????$$????rrrcccc,
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$C<<$$$$$PF<$$$$
$$$$$cizccCCCCCCCCCcccc$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$?????)>>J$CLccc$??""
$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$????ii?iiJJJ$$??"""
$$$$$$$$$$$$$??$$$$????P$$$???iiiiicccccc<<????)Cicc$P""      ..   .,;;!!!
$$$$$CCCCCCC>>J>>>>cccccc>>>??C????CC>cccJ$??"""""         -``!!;!'  .!!!'
$$$$$??CCCCCCCCCCCff>>>>>J$$$P""""""""            ..,;;;;;;;!'`.,;;!'''
??????????????"""""'' `'              .,..,;;;;!!!'```..```' .,.,;;;- `,;'
                    .,.    ,;;----'''''''```````'  `''`,;;!!'''`..,;;'' ,;
---;;;;;;;-----'''''''''``'  --- `'  .,,ccc$$hcccccc,.  `' ,;;!!!'``,;;!!'
;;;;,,.,;-------''''''' ,;;!!-    .zJ$$$$$$$$$$$$$$$$$$$c,. `' ,;;!!!!' ,;
  ```'    -;;;!'''''-  `.,..   .zJ$$$$$$$$$$$$$$$$$$$$$$$$$$c, `!!'' ,;!!'
!!-  ' `,;;;;;;;;;;'''''```' ,c$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$c,  ;!!'' ,;
,;;;!!!!!!!!''``.,;;;;!'`'  z$$$$$$$$???"""""'.,,.`"?$$$$$$$$$$$  ``,;;!!!
;;..       --''```_..,;;!  J$$$$$$??,zcd$$$$$$$$$$$$$$$$$$$$$$$$h  ``'``'
```'''   ,;;''``.,.,;;,  ,$$$$$$F,z$$$$$$$$$$$$$$$$$$$c,`""?$$$$$h
!!!!;;;;,   --`!'''''''  $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$h.`"$$$$h .
`'''``.,;;;!;;;--;;   zF,$$$$$$$$$$?????$$$$$$$$$$$$$?????$$r ;?$$$ $.
!;.,..,.````.,;;;;  ,$P'J"$$$$$$P" .,c,,.J$$$$$$$$$"',cc,_`?h.`$$$$ $L
'``````'    .,..  ,$$". $ $$$$P",c$$$$$$$$$$$$$$$$',$$$$$$$$$$ $$$$ $$c,
!!!!!!!!!!!!!'''  J$',$ $.`$$P c$$$$$$$$$$$$$$$$$$,$$$$$$$$$$$ $$$$ $$$$C
   ``            J$ ,$P $$ ?$',$$$$???$$$$$$$$$$$$$$$??"""?$$$ <$$$ $$$$$
c           ;,  z$F,$$  `$$ $ ?$"      "$$$.?$$$ $$$P c??c, ?$.<$$',$$$$$F
$$h.  -!>   ('  $" $F ,F ?$ $ F ,="?$$c,`$$F $$"z$$',$' ,$$P $h.`$ ?$$$$$r
$$$$$hc,. ``'  J$ $P J$ . $$F L ",,J$$$F <$hc$$ "$L,`??????,J$$$.` z$$$$$
$$$$$$$$$$c,'' ?F,$',$F.: $$ c$c,,,,,c,,J$$$$$$$ ?$$$c,,,c$$$$$$F. $$$$$$
`"$$$$$$$$$$$c, $$',$$ :: $$$$$$$$F"',$$$$$$$$$$h ?$$$L;;$$$??$$$$ $$$$$$
   "?$$$$$$$$$$ $$$$$$ : .`F"$$$$$$$$$$$$""""?"""h $$$$$$$"$,J$$$$ $$$$$'
      "?$$$$$$$ $$$$$$.`.` h `$$$$$$$$$$$cccc$$c,zJ$$$$$P' $$$$$P',$$$$P
$.       `""?$$ $$$$$$$  ` "$c "?$$$$$$$$$$$$??$$$$$$$$" ,J$$$P",J$$$$P
..           `" ?$$$$$$h    ?$$c.`?$$$$$$$$$' . <$$$$$' ,$$$"  ,$$$$$"
!!>. .          `$$$$$$$h  . "$$$c,"$$$$$$$' `' `$$$P  ,$$$' ,c$$$$$'   ;!
```<!!!>         `$$$$$$$c     "$$$c`?$$$$$  : : $$$  ,$$P' z$$$$$$'   ;!!
$hc ```'  ;       `$$$$$$$.      ?$$c ?$$$$ .: : $$$  $$F ,J$$$$$$'   ;!!
.,..      '        `$$$$$$$       "$$h`$$$$ .' ' $$$ ,$$ ,J$$$$$$'    !!!
????P               `$$$$$$L       $$$ $$$F :.: J$$P J$F J$$$$$P     ;!!
-=<                  ?$$."$$       `$$ ?$$' `' z$$$F $P  $$$$$$'     !!'
cc                   `$$$c`?        ?$.`$$hc, cd$$F ,$'  $$$$$$     ;!!
                      $$$$c         `$$c$$$$$$$$$",c$'   $$$$$$     `!!
                      $$$$$          `?$$$$$$$$$$$$P'    $$$$$$> ..
                      $$$$$            `"?$$$$$$$P"      $$$$$$L $$c,
          !!         <$$$$$            zc,`"""',         <$$$$$$.`$$$$cc,
          !!         J$$$$P            `$$$$$$$' !'       $$$$$$L `$$$$$$h
         ;,          $$$$$L          `! J$$$$$',!!        $$$$$$$  `$$$$$$
          '         <$$$$$.           ! $$$$$$ !!         ?$$$$$$   `$$$$$
                   ,$$$$$$$c          `,`???? ;'         c,?$$$$'    `?$$$
                   $$$$$$$??           `!;;;;!     .     `h."?$P      `$$$
                  ,$$$$$$$h.            `'''      `'      `$$$P        `?$
                   $$$$$$$$h                      `!'      `"'           `
                  `$$$$$$$$F          !;     !    ;,
                   `$$$$$$$'         `!!>         `!
c,        ;,        `?$$$$P           !!>             .
$F        !!>         `""'            `!!            ;!>    <-
$F       `!!'                      ;!; '   `!        <!>    ;
$F        `'      <!               !!!               !!>    !!
?'       `'      !!!               !!!               !!>    !!
         !!'    <!!               ;!!!               `'     ;
        ;!!     !!                !!!!                      !'
        !!!     `'                !!!                       '            ;
        !!                       ;!!'                                    !
                                 !!!                      ;!             !
                                <!!!                      )'            `!
          ,;;>                 ;!!!                                     `!
          `''                 ;!!!                     !                `!
              ;!             ;!!!                                  ,$$c, `
            !''             ;!!!           '                    ,c$$$$$$c.
>                       ;   !!!                                 ?$$$$$$$$$
!!>                   ;!! .!!!     .!>                           "?$$$$$$$
<! `!         ,;     ;!!  !!!!     !!                              `"?$$$$
 . '          '    ;!!! .!!!!     !!   .                              `"?$
 `'               <!!' .!!!!!!   !!!'  !                     >           `
                .!!!  <!!'`!!! .!!!!;                   !!>
                !!!  <!!'  !! ;!!!!!!                   (' ;,
               <!!  !!!'  !!! !!!'!!!                   !> `!
               !!' !!!'  `!!';!>  !!                 <! `' `!  !>.
               ' ;<!!'  .!!! !!' <!'       ;        `!! ;  `!  !!!>
            .<!>;!!!'   !!! `!! <!!                .. ' '      !!!' ;,
           <!!! <!! ;   !!! !!>;!!''!             J$$c         `!!; !!>
          ;!!! ;!! <!   !!> !! `!! !'            J$$$$hr        `'' !!!,;;
          ;!!! !! <!!  <!!  !' ;!! '            <$$$$$$$.           <!!!'!
          !!!  !;<!!'  !!! ;!  !!>              $$$$$$$$$$.          `'  !
         `!!! !!!!!'   !!! !! `!!!              ?$$$$$$$??$c        !!>;
         ;!! ;!!!!!   ;!!> !! <!!>               ?$$$$$$c,`$$.      `!!!
         !!! !!! !'   `!!> !! !!!                 "?$$$$$$ "?$c      `<!
        ;!!  !! ;!    !!!> ! ;!!!,                  "$$$$$$c,"?$c,
        ;!!  !! ;!    !!!! ! `!!!!                    "$$$$$$c ?$$h.
        !!!> !! !!    !!!!    !!!                       "?$$$$c "$$$c,
        !!!' '  !!    `!!!    `!                          "$$$$h.`?$$$c,
       <!!!>   <!!    `!!!     !>                          ?$$$$$c ?$$$$h.
       `!!!    `!!     !!!     `'                           "?$$$$h.`?$$$$
        `!!>    !!     `!!                                    `?$$$$$$$$$$
         `!'    !!      `'                                      "$$$$$$$$$
                `!>                                               ?$$$$$$$
                 `!                                                `"?$$$$
                  `-                ;!                                `"$$
                                                                        `?
EOS
      end
    end
  end
end
