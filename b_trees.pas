program b_trees;
{%REGION Head}
uses
  sysutils, crt
  ;

type
  PTreeNode  = ^TreeNode;            //btree vertex pointer
  TreeNode   = record                //btree vertex structure
    Order    : integer;
    Children : Array of PTreeNode;
    Items    : Array of integer;
    Parent   : PTreeNode;
  end;

  TreeItem   = record                //structure representing item inside btree
    HostNode : PTreeNode;
    index    : integer;
  end;

var
  //Command 'SHELL' specific values
  lastcommand        : string;
  lastvalue          : integer;
  lastvalueoccured   : boolean;
  negative           : boolean;

  //global range values
  btree              : PTreeNode;
  autoprint, refer   : integer;

  //Command 'SHELL' auxiliary variables
  i                  : integer;
  valfound, cmdfound : boolean;
  line               : string;

{%ENDREGION}


//Search the tree for a value, return leaf and index of parenting neigbor or self recursively
function SearchNodeTree(value: integer; var node: PTreeNode): TreeItem;
var
  i   : integer;
  res : TreeItem;
begin
  if Length(node^.Items) = 0 then
  begin
    res.HostNode := node;
    res.index := -1;
    SearchNodeTree := res;
  end

  else
  begin
    for i := 0 to High(node^.Items) do
    begin
      //found the rightless neigbor bigger than value on index i
      if node^.Items[i] > value then
      begin
        if Length(node^.Children) > 0 then
        begin
          SearchNodeTree := SearchNodeTree(value, node^.Children[i]);
          Break;
        end
        else
        begin
          res.HostNode := node;
          res.index := i;
          SearchNodeTree := res;
          Break;
        end;
      end

      //found value precisely
      else if node^.Items[i] = value then
      begin
        res.HostNode := node;
        res.index := i;
        SearchNodeTree := res;
        Break;
      end

      //value is bigger than all items in this node
      else if i = High(node^.Items) then
      begin
        if Length(node^.Children) > 0 then
        begin
          SearchNodeTree := SearchNodeTree(value, node^.Children[i + 1]);
          Break;
        end
        else
        begin
          res.HostNode := node;
          res.index := i;
          SearchNodeTree := res;
          Break;
        end;
      end;
    end;
  end;
end;

//Try to find the value in the tree and print result
procedure Find;
var
  t: TreeItem;
begin
  if lastvalueoccured then
  begin
    Write('Number ' + IntToStr(lastvalue) + ' ');
    t := SearchNodeTree(lastvalue, btree);
    if (t.index >= 0) and (t.HostNode^.Items[t.index] = lastvalue) then
      WriteLn('was found.')
    else
      WriteLn('wasn''t found');
  end

  else
  begin
    if refer >= 1 then
      WriteLn('Searches the tree for a value. Please type ''find <INT>''' +
              '(without apostrophes) to search for the <INT> number.');
  end;
end;


//Delete a node of a tree and the whole child tree under it recursively
procedure DeleteNodeTree(var node: PTreeNode);
var
  i : Integer;
begin
  if (node <> NIL) then
  begin
    //Dispose subnodes
    for i := 0 to High(node^.Children) do
      DeleteNodeTree(node^.Children[i]);

    //Dispose self
    Dispose(node);
    node := NIL;
  end;
end;


//Add a value to the tree
procedure AddVal;
var
  spot                    : TreeItem;
  splitnode, splitsibling : PTreeNode;
  i, index, addup         : Integer;
begin
  if lastvalueoccured then
  begin
    if refer >= 1 then
      WriteLn('Adding ' + IntToStr(lastvalue) + ' to the tree...');

    //leaf into which is being added or vertex with lastvalue
    spot := SearchNodeTree(lastvalue, btree);

    //if spot reffers to last value, don't add
    if (spot.index >= 0) and (spot.HostNode^.Items[spot.index] = lastvalue) then
    begin
      if refer >= 1 then
        WriteLn('Adding failed - ' + IntToStr(lastvalue) + ' is already in the tree!');
    end

    else
    begin
      //expand leaf's Items
      SetLength(spot.HostNode^.Items, Length(spot.HostNode^.Items) + 1);

      //shift values inside leaf's Items, i will hold the index for lastvalue
      if spot.index >= 0 then
      begin
        for i := (High(spot.HostNode^.Items) - 1) downto (spot.index + 1) do
          spot.HostNode^.Items[i + 1] := spot.HostNode^.Items[i];

        if spot.HostNode^.Items[spot.index] > lastvalue then
        begin
          i := spot.index;
          spot.HostNode^.Items[i + 1] := spot.HostNode^.Items[i];
        end
        else
          i := spot.index + 1;
      end
      else
        i := 0;

      spot.HostNode^.Items[i] := lastvalue;

      //check if leaf has to be splitted
      if spot.HostNode^.Order < Length(spot.HostNode^.Items) then
        splitnode := spot.HostNode
      else
        splitnode := NIL;

      //recursive node splitting
      while splitnode <> NIL do
      begin
        //index on which the node is splitted
        index := splitnode^.Order div 2;

        //item which will be sent to previous level
        addup := splitnode^.Items[index];

        //prepare new neigboring node (sibling node)
        New(splitsibling);
        splitsibling^.Order := splitnode^.Order;  
        splitsibling^.Parent := splitnode^.Parent;
        SetLength(splitsibling^.Items, (splitnode^.Order + 1) div 2);
        if Length(splitnode^.Children) > 0 then
          SetLength(splitsibling^.Children, ((splitnode^.Order + 1) div 2) + 1)
        else
          SetLength(splitsibling^.Children, 0);

        //copy respectful items and children to sibling node
        for i := (index + 1) to High(splitnode^.Items) do
        begin
          splitsibling^.Items[i - index - 1] := splitnode^.Items[i];            
          if Length(splitnode^.Children) > 0 then                   
            splitsibling^.Children[i - index - 1] := splitnode^.Children[i];
        end;
        if Length(splitnode^.Children) > 0 then
          splitsibling^.Children[i - index] := splitnode^.Children[i + 1];

        //set new correct length to splitnode
        SetLength(splitnode^.Items, index);
        if Length(splitnode^.Children) > 0 then
          SetLength(splitnode^.Children, index + 1);

        //if splitnode is not root, send addup to parent
        if splitnode^.Parent <> NIL then
        begin
          //find index for addup inside parent by pointer to splitnode
          for i := 0 to High(splitnode^.Parent^.Children) do
          begin
            if splitnode^.Parent^.Children[i] = splitnode then
            begin
              index := i;
              Break;
            end;
          end;

          //expand parent
          SetLength(splitnode^.Parent^.Items, Length(splitnode^.Parent^.Items) + 1);
          SetLength(splitnode^.Parent^.Children, Length(splitnode^.Parent^.Children) + 1);

          //shift items and children inside parent
          for i := High(splitnode^.Parent^.Items) downto (index + 1) do
          begin
            splitnode^.Parent^.Items[i] := splitnode^.Parent^.Items[i - 1];
            splitnode^.Parent^.Children[i + 1] := splitnode^.Parent^.Children[i];
          end;

          splitnode^.Parent^.Items[index] := addup;
          splitnode^.Parent^.Children[index + 1] := splitsibling;

          //check if parent has to be splitted
          if splitnode^.Parent^.Order < Length(splitnode^.Parent^.Items) then
            splitnode := splitnode^.Parent
          else
            splitnode := NIL;
        end

        //create new root with addup
        else
        begin
          btree := NIL;
          New(btree);
          btree^.Parent := NIL;
          btree^.Order := splitnode^.Order;
          SetLength(btree^.Items, 1);
          SetLength(btree^.Children, 2);
          btree^.Items[0] := addup;
          btree^.Children[0] := splitnode;
          btree^.Children[1] := splitsibling;
          splitnode^.Parent := btree;        
          splitsibling^.Parent := btree;
          splitnode := NIL;
        end;
      end;

      if refer >= 1 then
        WriteLn(IntToStr(lastvalue) + ' was successfully added to the tree!');
    end;
  end

  else
  begin
    if refer >= 1 then
      WriteLn('Adds value to the tree. Please type ''add <INT>''' +
              '(without apostrophes) to add the <INT> number in.');
  end;
end;

//Remove a value from the tree
procedure RemVal;
var
  spot : TreeItem;
begin
  {if lastvalueoccured then
  begin
    WriteLn('Deleting ' + IntToStr(lastvalue) + ' from the tree...');
    spot := SearchNodeTree(lastvalue, btree);
    if (spot.index < 0) or (spot.HostNode^.Items[spot.index] <> lastvalue) then
    begin
      if refer >= 1 then
        WriteLn('Cannot Delete - ' + IntToStr(lastvalue) + ' is not the tree!');
    end

    else
    begin

    end;
  end

  else
  begin
    if refer >= 1 then
      WriteLn('Removes value from the tree. Please type ''remove <INT>''' +
              '(without apostrophes) to remove the <INT> number.');
  end; }

  WriteLn('Not Implemented, sorry...');
end;


//Print the tree
procedure PrintTree(clean: boolean);
var
  CurrentItems, NextItems : Array of PTreeNode;
  i, j, level             : integer;
  addup                   : boolean;
begin
  //tree with at least one item exists
  if (btree <> NIL) and (Length(btree^.Items) > 0) then
  begin
    if clean then
      ClrScr;

    //initialize with the root (btree)
    SetLength(CurrentItems, 1);
    CurrentItems[0] := btree;
    level := 1;

    //while next level contains nodes
    while Length(CurrentItems) > 0 do
    begin
      SetLength(NextItems, 0);
      WriteLn;
      Write('LVL' + IntToStr(level) + ': ');

      //for each node on level
      for i := 0 to High(CurrentItems) do
      begin
        //NIL as current item means extra space
        if CurrentItems[i] <> NIL then
        begin
          Write('|');
          addup := Length(CurrentItems[i]^.Children) > 0;  //defacto 'Is not leaf'

          //for each item in current node
          for j := 0 to High(CurrentItems[i]^.Items) do
          begin
            Write(IntToStr(CurrentItems[i]^.Items[j]) + '|');
            //add child of next level
            if addup then
            begin
              SetLength(NextItems, Length(NextItems) + 1);
              NextItems[High(NextItems)] := CurrentItems[i]^.Children[j];
            end;
          end;

          //add last child of next level
          if addup then
          begin
            SetLength(NextItems, Length(NextItems) + 2);
            NextItems[High(NextItems) - 1] := CurrentItems[i]^.Children[Length(CurrentItems[i]^.Items)];

            //add fake child for extra space - separates node groups by parents
            NextItems[High(NextItems)] := NIL;
          end;

          Write(' ');
        end

        else
          Write(' ');
      end;

      level := level + 1;

      CurrentItems := NextItems;
    end;

    WriteLn;
  end

  else
  begin
    if refer >= 1 then
      WriteLn('Error - Tree is empty!');
  end;
end;

//Delete the whole tree and begin from scratch
procedure Reset;
label Readorder;
var
  order, i : integer;
  line     : string;
begin
  if (refer >= 1) and (btree <> NIL) then
    WriteLn('Deleting the old tree...');
  DeleteNodeTree(btree);
                            
  //Horner scheme addup of new btree order
  Readorder:
  WriteLn('Please type the tree order (integer 2 and bigger):');
  ReadLn(line);
  order := 0;

  for i := 1 to Length(line) do
  begin
    if (ord(line[i]) >= 48) and (ord(line[i]) <= 57) then
      order := (order * 10) + StrToInt(line[i])
    else
    begin
      if line[i] <> ' ' then
      begin
        order := 0;
        Break;
      end;
    end;
  end;

  if order < 2 then
    goto Readorder;

  //create new btree
  New(btree);
  btree^.Order := order;
  SetLength(btree^.Children, 0);
  SetLength(btree^.Items, 0);
  btree^.Parent := NIL;
end;


//Performs setting of autoprint option
procedure SetAPrint;
begin
  if lastvalueoccured and (lastvalue >= 0) and (lastvalue <= 2) then
  begin
    autoprint := lastvalue;
    if refer >= 1 then
      WriteLn('Successfully set autoprint to ' + IntToStr(autoprint));
  end

  else
    WriteLn('Sets if the tree should be printed after a change occurs. ' +
            'Type ''autoprint <0|1|2>'' (without aphostrophes) to set. ' +
            '0 -> Off, 1 -> On, 2 -> On and clear screen (Currently ' +
            IntToStr(autoprint) + ' )');
end;
                              
//Performs setting of refer option
procedure SetRefer;
begin
  if lastvalueoccured and (lastvalue >= 0) and (lastvalue <= 2) then
  begin
    refer := lastvalue;
    if refer >= 1 then
      WriteLn('Successfully set autoprint to ' + IntToStr(refer));
  end

  else
    WriteLn('Sets if commands should write messages about their progress. ' +
            'Type ''refer <0|1|2>'' (without aphostrophes) to set. ' +
            '0 -> Off, 1 -> On, 2 -> On and clear screen. (Currently ' +
            IntToStr(refer) + ' )');
end;


//Display greeting message to the user
procedure GreetUsr;
begin
  ClrScr;
  WriteLn;
  WriteLn(' Hello, welcome to B-Tree testing program by Krepsy3, 2019.');
  WriteLn(' To display available commands, type "help"');
  WriteLn;

  if btree = NIL then
    Reset;
end;

//Display Help Text to the User
procedure DisplayHelp;
begin
  WriteLn;
  WriteLn(' AVAILABLE COMMANDS:');
  WriteLn(' ===================');
  WriteLn('   help              -> Displays this list');
  WriteLn('   clear             -> Clears the screen');
  WriteLn('   restart           -> Disposes the B-tree and begins again');
  WriteLn('   exit              -> Aborts the program execution');
  WriteLn('   print             -> Clear the screen & print out the tree');
  WriteLn('   add <INTEGER>     -> Try to add this integer to the tree');
  WriteLn('   remove <INTEGER>  -> Try to delete this integer from the tree');
  WriteLn('   find <INTEGER>    -> Search the tree for this integer');
  WriteLn('   autoprint <0|1|2> -> Set if printing should happen automatically on each change');
  WriteLn('   refer <0|1|2>     -> Set if commands should write info about progress');
  WriteLn('   greet             -> Display the greeting message');
end;


//MAIN LOOP - Initialization + Command 'SHELL'
begin
  //Init values of global variables
  lastcommand := 'greet';
  lastvalue := 0;
  lastvalueoccured := false;
  autoprint := 0;
  refer := 1;

  //while command is not 'exit'
  while CompareText(lastcommand, 'exit') <> 0 do
  begin
    //Clear the screen if refer is 2 before executing reffering command
    if ((lastcommand = 'restart') or (lastcommand = 'remove')
        or (lastcommand = 'add') or (lastcommand = 'find') or (lastcommand = 'print')
        or (lastcommand = 'autoprint') or (lastcommand = 'refer'))
       and (refer = 2) then
      ClrScr;
             
    //Clear the screen if autoprint is 2 before executing autoprinting command
    if ((lastcommand = 'restart') or (lastcommand = 'remove') or (lastcommand = 'add'))
       and (autoprint = 2) then
      ClrScr;

    //Execute last command
    case lastcommand of
      'greet'     : GreetUsr;
      'help'      : DisplayHelp;
      'clear'     : ClrScr;
      'restart'   : Reset;
      'add'       : AddVal;
      'remove'    : RemVal;
      'find'      : Find;
      'print'     : PrintTree(true);
      'autoprint' : SetAPrint;
      'refer'     : SetRefer;

      otherwise WriteLn(' Unknown command. Type ''help'' to check...')
    end;

    //Print tree if autoprint is 1 or 2 after autoprinting command was executed
    if ((lastcommand = 'restart') or (lastcommand = 'remove') or (lastcommand = 'add'))
        and (autoprint >= 1) then
      PrintTree(false);

    //Read user input and reset global variables before analysing next command
    ReadLn(line);
    valfound := false;
    cmdfound := false;
    lastcommand := '';
    lastvalue := 0;
    lastvalueoccured := false;
    negative := false;

    for i:= 1 to Length(line) do
    begin
      //cut off leading ' '
      if (not cmdfound) then
      begin
        if line[i] <> ' ' then
        begin
          cmdfound := true;
        end;
      end;

      if cmdfound then
      begin
        if (not valfound) then
        begin
          if line[i] = ' ' then
            valfound := true

          //case-insensitive command completion
          else
          begin
            if (ord(line[i]) >= ord('a')) and (ord(line[i]) <= ord('z')) then
              lastcommand := lastcommand + line[i]
            else if (ord(line[i]) >= ord('A')) and (ord(line[i]) <= ord('Z')) then
              lastcommand := lastcommand + chr(ord(line[i]) + ord('a') - ord('A'));
          end;
        end

        //add integer value using the Horner Scheme
        else
        begin
          if (ord(line[i]) >= ord('0')) and (ord(line[i]) <= ord('9')) then
          begin
            lastvalue := (lastvalue * 10) + StrToInt(line[i]);
            lastvalueoccured := true;
          end

          else if line[i] = '-' then
            negative := not negative

          else
            Break;
        end;
      end;
    end;

    if negative then
      lastvalue := -lastvalue;
  end;
end.
